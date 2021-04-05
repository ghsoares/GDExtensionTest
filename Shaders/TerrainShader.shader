shader_type canvas_item;

uniform sampler2D terrainHeightMap;
uniform vec2 terrainSize = vec2(1024, 640);
uniform float terrainResolution = .25f;

uniform sampler2D terrainNoise;
uniform float terrainNoiseTiling = 256f;
uniform float terrainNoiseDistortionTiling = 333f;
uniform float terrainNoiseDistortionAmount = 32f;
uniform float terrainNoiseEaseCurve = -2f;
uniform float terrainNoiseSteps = 8f;

uniform sampler2D heightRemapCurve;
uniform float heightRemapCurveRange = 512f;

uniform sampler2D terrainGradient;

varying vec2 v;

float Ease(float x, float c) {
	x = clamp(x, 0f, .999f);
	float curve1 = 1f - pow(1f - x, 1f / c);
	float curve2 = pow(x, c);
	float curve3 = pow(x * 2f, -c) * .5f;
	float curve4 = (1f - pow(1f - (x - .5f) * 2f, -c)) * .5f + .5f;
	float curveA = mix(curve1, curve2, step(1f, c));
	float curveB = mix(curve3, curve4, step(.5f, x));
	return mix(curveB, curveA, step(0f, c));
}

float GetTerrainHeight(float x) {
	float height1 = texture(terrainHeightMap, vec2(x, 0f) / terrainSize).r;
	float height2 = texture(terrainHeightMap, vec2(x + 1f / terrainResolution, 0f) / terrainSize).r;
	float t = fract(x * terrainResolution);
	float h = mix(height1, height2, t);
	return h * terrainSize.y;
}

float GetTerrainY(float x) {
	return terrainSize.y - GetTerrainHeight(x);
}

void vertex() {
	v = VERTEX;
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
	
	n = floor(n * (terrainNoiseSteps + 1f)) / terrainNoiseSteps;
	n = clamp(n, 0f, 1f);
	
	vec4 col = texture(terrainGradient, vec2(n));
	
	col.a *= step(terrainY, v.y);
	
	return col;
}

void fragment() {
	COLOR *= GetTerrainColor();
}






