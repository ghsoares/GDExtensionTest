shader_type canvas_item;

uniform sampler2D heightMap;
uniform sampler2D terrainGradient;
uniform float resolution;
uniform vec2 size;

uniform sampler2D fogNoise;
uniform float fogTiling = 512f;
uniform vec2 fogHeightRange = vec2(32f, 256f);
uniform vec2 fogAddRange = vec2(-1f, 1f);
uniform float fogSteps = 8f;

uniform vec2 motion = vec2(32f, 0f);

uniform int octaves = 1;
uniform float lacunarity = 1.5f;
uniform float persistance = .25f;
uniform sampler2D fogGradient;

varying vec2 v;

float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}

float ease(float x, float c) {
	if (x < 0f) x = 0f;
	if (x > 1f) x = 1f;
	
	if (c > 0f) {
		if (c < 1f) {
			return 1f - pow(1f - x, 1f / c);
		} else {
			return pow(x, c);
		}
	} else if (c < 0f) {
		if (x < 0.5f) {
			return pow(x * 2f, -c) * .5f;
		} else {
			return (1f - pow(1f - (x - .5f) * 2f, -c)) * .5f + .5f;
		}
	}
	
	return 0f;
}

float sample_height(float x) {
	float heightMapPixelSize = 1.0 / (size.x * resolution);
	
	float uvX = x / size.x;
	
	float height = texture(heightMap, vec2(uvX, 0.0)).r;
	float right = texture(heightMap, vec2(uvX + heightMapPixelSize, 0.0)).r;
	
	float t = fract(x * resolution);
	
	return mix(height, right, t) * size.y;
}

void vertex() {
	v = VERTEX;
}

float get_fog(vec2 pos) {
	vec2 uv = pos / fogTiling;
	float n = texture(fogNoise, uv).r;
	
	return n;
}

void fragment() {
	vec2 pos = v;
	
	float n = 0f;
	float freq = 1f;
	float mult = 1f;
	for (int i = 0; i < octaves; i++) {
		vec2 off = motion * TIME / freq;
		n = mix(n, 1f, clamp(get_fog(pos * freq + off) * mult, 0, 1));
		freq *= lacunarity;
		mult *= persistance;
	}
	
	float height = size.y - pos.y;
	float t = (height - fogHeightRange.x) / (fogHeightRange.y - fogHeightRange.x);
	
	n += mix(fogAddRange.x, fogAddRange.y, clamp(t, 0, 1));
	
	n = clamp(n, 0f, 1f);
	n = floor(n * fogSteps) / fogSteps;
	
	vec3 col = texture(fogGradient, vec2(1f - n, 0f)).rgb;
	
	COLOR.rgb = col;
	COLOR.a = n;
}


