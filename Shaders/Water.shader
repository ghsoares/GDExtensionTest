shader_type canvas_item;

uniform vec4 color : hint_color = vec4(1.0);
uniform vec4 foamColor : hint_color = vec4(1.0);

uniform float windSpeed;

uniform int waveOctaves = 1;
uniform float waveSpeed = 2.0;
uniform float wavePeriod = 64.0;
uniform float waveLacunarity = 2.0;
uniform float waveSpeedLacunarity = 2.0;
uniform float wavePersistance = .75;
uniform float waveMagnitude = 4.0;

uniform sampler2D noise;
uniform vec2 noiseMotion = vec2(32.0, 0.0);
uniform float noiseTiling = 64.0;
uniform float noiseMagnitude = 8.0;

uniform float topFoam = 2.0;
uniform sampler2D foamNoise;
uniform vec2 foamNoiseMotion = vec2(16.0, 0.0);
uniform float foamNoiseTiling = 64.0;
uniform float foamTransition = 8.0;
uniform float foamNoiseMagnitude = .1;
uniform float foamNoiseThreshold = .5;

uniform mat4 world_transform;

varying vec2 v;
varying vec2 world_v;
varying float time;

void vertex() {
	v = VERTEX;
	world_v = (world_transform * vec4(VERTEX, 0.0, 1.0)).rg;
	time = TIME;
}

float GetWave() {
	float wave = 0.0;
	
	float period = wavePeriod;
	float persistance = 1.0;
	float two_pi = radians(360.0);
	float motion = waveSpeed;
	
	for (int i = 0; i < waveOctaves; i++) {
		float pos = world_v.x + time * motion + time * -windSpeed;
		float s = sin((pos / period) * two_pi) * .5 + .5;
		wave += s * persistance;
		persistance *= wavePersistance;
		period /= waveLacunarity;
		motion *= waveSpeedLacunarity;
	}
	
	return wave / float(waveOctaves);
}

void fragment() {
	float wave = GetWave() * waveMagnitude;
	if (v.y < wave) discard;
	
	vec4 col = color;
	
	float diff = v.y - wave;
	
	float foam = 0.0;
	
	foam = 1.0 - step(topFoam, diff);
	
	float foamT = 1.0 - (diff - topFoam) / (foamTransition - topFoam);
	foamT -= 1.0;
	float foamN = texture(foamNoise, (world_v + foamNoiseMotion * TIME) / foamNoiseTiling).r;
	foamT += foamN * foamNoiseMagnitude;
	foamT = clamp(foamT, 0.0, 1.0);
	foamT = step(foamNoiseThreshold, foamT);
	foam = max(foam, foamT);
	
	col = mix(col, foamColor, foam);
	
	vec2 scUv = SCREEN_UV;
	vec2 scOff = vec2(0.0);
	
	vec2 noiseUv = (world_v + noiseMotion * TIME) / noiseTiling;
	vec2 noiseOff = texture(noise, noiseUv).rg * 2.0 - 1.0;
	scOff += noiseOff * noiseMagnitude;
	
	scUv += scOff * SCREEN_PIXEL_SIZE;
	
	vec4 scCol = textureLod(SCREEN_TEXTURE, scUv, 0.0);
	
	col.rgb = mix(scCol.rgb, col.rgb, col.a);
	col.a = 1.0;
	
	COLOR = col;
}


