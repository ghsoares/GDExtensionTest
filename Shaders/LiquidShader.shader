shader_type canvas_item;

uniform mat4 worldMatrix;

uniform sampler2D ditheringTexture;
uniform float ditheringInfluence = .1;

uniform vec4 color: hint_color = vec4(.5, .9, 1.0, .5);
uniform vec4 color2: hint_color = vec4(.5, .9, 1.0, .5);
uniform vec4 surfaceColor: hint_color = vec4(1.0);
uniform float surfaceSize = 2.0;
uniform float colorTransition = 32.0;
uniform float colorTransitionSteps = 8.0;

uniform float windSpeed;

uniform sampler2D refractionTexture;
uniform vec2 refractionMotion;
uniform float refractionTiling = 32;
uniform float refractionPower = 4.0;

uniform int waveOctaves = 1;
uniform float wavePeriod = 64;
uniform float waveLacunarity = 2.0;
uniform float wavePersistance = .25;

uniform float maxMagnitude = 32.0;
uniform float limitTransition = 32.0;

varying vec2 v;
varying vec2 worldV;
varying float time;

void vertex() {
	VERTEX.y -= (1.0 - UV.y) * maxMagnitude;
	v = VERTEX;
	time = TIME;
	worldV = (worldMatrix * vec4(VERTEX, 0.0, 1.0)).rg;
}

float GetWaveHeight() {
	float pi = radians(360.0);
	
	float h = 0.0;
	int oct = max(waveOctaves, 1);
	
	float period = wavePeriod;
	float pers = 1.0;
	for (int i = 0; i < oct; i++) {
		float s = sin((worldV.x / period) * pi - (windSpeed / wavePeriod) * time * 64.0) * .5 + .5;
		h += s * pers;
		
		period /= waveLacunarity;
		pers *= wavePersistance;
	}
	
	h *= abs(windSpeed / 8.0);
	
	return clamp(h / float(oct), -maxMagnitude, maxMagnitude);
}

void fragment() {
	vec2 size = v / UV;
	
	vec2 scUv = SCREEN_UV;
	
	vec2 motion = refractionMotion;
	motion.x -= windSpeed;
	
	vec2 refr = texture(refractionTexture, (worldV + motion * TIME) / refractionTiling).rg * 2.0 - 1.0;
	scUv += refr * refractionPower * SCREEN_PIXEL_SIZE;
	
	scUv = floor(scUv / SCREEN_PIXEL_SIZE) * SCREEN_PIXEL_SIZE;
	scUv += SCREEN_PIXEL_SIZE * .5;
	
	float h = -GetWaveHeight();
	
	float diff = v.y - h;
	float t = diff / colorTransition;
	
	vec2 ditherSize = vec2(textureSize(ditheringTexture, 0));
	float d = texture(ditheringTexture, v / ditherSize).r * 2.0 - 1.0;
	
	t -= d * ditheringInfluence;
	
	t = floor(t * colorTransitionSteps) / colorTransitionSteps;
	t = clamp(t, 0.0, 1.0);
	
	float borderTransition = v.x / limitTransition;
	borderTransition = min(borderTransition,
		(size.x - v.x) / limitTransition
	);
	borderTransition = clamp(borderTransition, 0.0, 1.0);
	h *= borderTransition;
	
	vec4 col = textureLod(SCREEN_TEXTURE, scUv, 0.0);
	vec4 waterCol = mix(surfaceColor, mix(color, color2, t), step(h + surfaceSize, v.y));
	
	col.rgb = mix(col.rgb, waterCol.rgb, waterCol.a);
	
	COLOR = col;
	
	COLOR.a *= step(h, v.y);
}




