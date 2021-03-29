shader_type canvas_item;

uniform sampler2D ditheringTexture;
uniform float ditheringInfluence = .1;

uniform sampler2D fogNoise;
uniform float fogTiling = 512.0;

uniform vec2 fogMotion;
uniform float windSpeed;

uniform int fogOctaves = 2;
uniform float fogLacunarity = 2.0;
uniform float fogPersistance = .25;

uniform sampler2D heightSubtractCurve;
uniform float fogSteps = 8.0;

uniform sampler2D fogGradient;
uniform mat4 playerTransform;
uniform float playerFadeLength = 64.0;

varying vec2 v;
varying float time;

float Ease(float x, float c) {return x;}

void vertex() {
	v = VERTEX;
	time = TIME;
}

float GetNoise() {
	float n = 0.0;
	
	int oct = max(fogOctaves, 1);
	
	vec2 motion = fogMotion;
	motion.x += windSpeed * 4.0;
	
	float period = fogTiling;
	float pers = 1.0;
	
	float total = 0.0;
	
	for (int i = 0; i < oct; i++) {
		vec2 uv = v / period;
		uv -= (motion / fogTiling) * time;
		n += texture(fogNoise, uv).r * pers;
		
		total += pers;
		
		period /= fogLacunarity;
		pers *= fogPersistance;
	}
	
	return n / max(total, 1.0);
}

void fragment() {
	float n = GetNoise();
	n = Ease(n, -2.0);
	
	n -= texture(heightSubtractCurve, vec2(UV.y, 0.0)).r;
	
	vec2 ditherSize = vec2(textureSize(ditheringTexture, 0));
	float d = texture(ditheringTexture, v / ditherSize).r * 2.0 - 1.0;
	
	vec2 playerOrigin = playerTransform[3].xy;
	vec2 playerOff = (playerOrigin - v);
	float fade = clamp(length(playerOff) / playerFadeLength, 0.0, 1.0);
	n *= fade;
	
	n += d * ditheringInfluence;
	
	n = floor(n * fogSteps) / fogSteps;
	n = clamp(n, 0.0, 1.0);
	
	vec4 col = texture(fogGradient, vec2(n, 0.0));
	
	COLOR = col;
}







