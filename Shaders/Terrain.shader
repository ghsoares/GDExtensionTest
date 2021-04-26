shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D terrainHeightMap;
uniform vec2 terrainSize = vec2(1024, 640);
uniform float terrainResolution = .25f;

uniform sampler2D terrainNoise;
uniform float terrainNoiseTiling = 256f;
uniform float terrainNoiseDistortionTiling = 333f;
uniform float terrainNoiseDistortionAmount = 32f;
uniform float terrainNoiseEaseCurve = -2f;
uniform float terrainNoiseSteps = 8f;

uniform sampler2D ditheringTexture;
uniform vec2 ditheringSize = vec2(32f);
uniform float ditheringInfluence = .01f;

uniform sampler2D heightRemapCurve;
uniform float heightRemapCurveRange = 512f;

uniform sampler2D terrainGradient : hint_albedo;

varying vec2 v;

float Ease(float x, float c) {
	x = clamp(x, 0f, 1f);
	
	float curve1 = 1f - pow(1f - x, 1f / c);
	float curve2 = pow(x, c);
	
	float curve3 = pow(x * 2f, -c) * .5f;
	float curve4 = (1f - pow(1f - (x - .5f) * 2f, -c)) * .5f + .5f;
	
	float curveA = c < 1f ? curve1 : curve2;
	float curveB = x < .5f ? curve3 : curve4;
	
	return c == 0f ? 0f : (c > 0f ? curveA : curveB);
}

float GetTerrainHeight(float x) {
	float height1 = texture(terrainHeightMap, vec2(x, 0f) / terrainSize).r;
	float height2 = texture(terrainHeightMap, vec2(x + 1f / terrainResolution, 0f) / terrainSize).r;
	float t = fract(x * terrainResolution);
	float h = mix(height1, height2, t) * terrainSize.y;
	return h;
}

float GetTerrainY(float x) {
	float h = GetTerrainHeight(x);
	return terrainSize.y - h;
}

vec4 GetTerrainColor() {
	float terrainY = GetTerrainY(v.x);
	float heightDiff = (v.y - terrainY);
	
	float n = texture(terrainNoise, v / terrainNoiseDistortionTiling).r * radians(360f);
	vec2 dist = vec2(cos(n), sin(n)) * terrainNoiseDistortionAmount;
	vec2 uv = (v + dist) / terrainNoiseTiling;
	
	n = texture(terrainNoise, uv).r;
	
	float remapT = clamp(heightDiff / heightRemapCurveRange, 0f, 1f);
	n += texture(heightRemapCurve, vec2(remapT)).r;
	
	n = Ease(n, terrainNoiseEaseCurve);
	
	float d = texture(ditheringTexture, v / ditheringSize).r * 2f - 1f;
	n += d * ditheringInfluence;
	
	n = floor(n * (terrainNoiseSteps + 1f)) / terrainNoiseSteps;
	n = clamp(n, 0f, 1f);
	
	vec4 col = texture(terrainGradient, vec2(n));
	
	col.a *= step(0f, heightDiff);
	
	return col;
}

void vertex() {
	v = VERTEX.xy / 0.01f;
	v.y = -v.y;
}

void fragment() {
	vec4 col = GetTerrainColor() * COLOR;
	//vec4 col = vec4(UV, 1f, 1f);
	ALBEDO = col.rgb;
	ALPHA = col.a;
	ALPHA_SCISSOR = 0.99f;
}