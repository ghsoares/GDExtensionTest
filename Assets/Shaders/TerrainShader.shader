shader_type canvas_item;

uniform vec2 terrainSize = vec2(640, 320);
uniform sampler2D terrainHeightMap;
uniform sampler2D tex;
uniform sampler2D terrainGradient;
uniform float texWarp = 0.1f;
uniform float texSteps = 4f;
uniform float texAdd = 0f;
uniform float texEasing = 1f;
uniform vec2 texFadeOutLenRange = vec2(32f, 128f);
uniform vec3 texFadeOutRange = vec3(1f, .5f, .25f);
uniform float tilingSize = 32f;
uniform float heightMapResolution = .25f;

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
	float hC = texture(terrainHeightMap, vec2(x, 0f)).r;
	
	return hC * terrainSize.y;
}

vec2 sample_normal(float x) {
	float spacing = 2f / terrainSize.x;
	float hl = sample_height(x - spacing);
	float hr = sample_height(x + spacing);
	vec2 n = normalize(vec2(hl - hr, -1f));
	return n;
}

vec4 hill_color(vec2 terrainUV) {
	vec2 uv = terrainUV;
	uv.y = 1f - uv.y;
	vec2 pos = uv * terrainSize;
	
	float h = sample_height(terrainUV.x);
	
	vec2 texUv = pos / tilingSize;
	float warpAngle = texture(tex, texUv * .345f).r * 3.1415 * 4f;
	texUv += vec2(cos(warpAngle), sin(warpAngle)) * texWarp;
	float terrain = ease(texture(tex, texUv).r, texEasing) + texAdd;
	
	float diff = h - pos.y;
	float terrainFade = 1f;
	if (diff < texFadeOutLenRange.x) {
		float fadeT = clamp(diff / texFadeOutLenRange.x, 0, 1);
		terrainFade = mix(texFadeOutRange.x, texFadeOutRange.y, fadeT);
	} else {
		float fadeT = (diff - texFadeOutLenRange.x) / (texFadeOutLenRange.y - texFadeOutLenRange.x);
		fadeT = clamp(fadeT, 0, 1);
		terrainFade = mix(texFadeOutRange.y, texFadeOutRange.z, fadeT);
	}	
	terrain *= terrainFade;
	
	terrain = clamp(ceil(terrain * texSteps) / texSteps, 0, 1);
	
	vec4 col = texture(terrainGradient, vec2(terrain, 0));
	
	if (pos.y > h) {
		col.a = 0f;
	}
	
	return col;
}

void fragment() {
	vec4 col = hill_color(UV);
	
	COLOR = col;
}

