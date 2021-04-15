shader_type canvas_item;

uniform mat4 globalTransform;

uniform sampler2D noise;
uniform float noiseLod = 1f;
uniform vec2 noiseOffset;
uniform vec2 noiseMotion;
uniform vec2 noisePeriod = vec2(512f);
uniform vec2 noiseOffsetPeriod = vec2(1f);
uniform int noiseOctaves = 1;
uniform float noiseLacunarity = 2f;
uniform float noiseOffsetLacunarity = 1.5f;
uniform float noisePersistance = .5f;
uniform float noiseEaseCurve = -2f;
uniform float noiseBumpness = 8f;
uniform float noiseThreshold = .1f;
uniform sampler2D fadeCurve;
uniform sampler2D fadeNormalCurve;
uniform vec3 lightDirection;
uniform float dotMultiply = 2f;
uniform sampler2D ditheringTexture;
uniform vec2 ditheringSize = vec2(32f);
uniform float ditheringInfluence = .01f;
uniform float dotSteps = 8f;
uniform sampler2D lightGradient;

varying float time;
varying vec2 worldV;
varying vec2 uv;

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

float GetNoise(vec2 v) {
	float n = 0f;
	
	vec2 period = noisePeriod;
	vec2 offPeriod = noiseOffsetPeriod;
	float persistance = 1f;
	
	float thisN = 0f;
	
	/* For loop section */
	thisN = Ease(textureLod(
		noise, v / period - (noiseOffset + noiseMotion * time) / offPeriod, noiseLod).r, noiseEaseCurve
	) * 2f - 1f;
	n += thisN * persistance;
	
	period /= noiseLacunarity;
	offPeriod /= noiseOffsetLacunarity;
	persistance *= noisePersistance;
	/* ---------------- */
	/* For loop section */
	thisN = Ease(textureLod(
		noise, v / period - (noiseOffset + noiseMotion * time) / offPeriod, noiseLod).r, noiseEaseCurve
	) * 2f - 1f;
	n += thisN * persistance;
	
	period /= noiseLacunarity;
	offPeriod /= noiseOffsetLacunarity;
	persistance *= noisePersistance;
	/* ---------------- */
	
	return n * .5f + .5f; //clamp(n * .5f + .5f, 0f, 1f);
}

vec3 GetNormal(vec2 v) {
	float spacing = 1f;
	
	float nc = GetNoise(v);
	
	float nx = GetNoise(v + vec2(spacing, 0f)) - nc;
	float ny = GetNoise(v + vec2(0f, spacing)) - nc;
	
	vec2 normal2D = vec2(nx, ny) * noiseBumpness;
	return vec3(normal2D, 1f);
}

void vertex() {
	time = TIME;
	worldV = (globalTransform * vec4(VERTEX, 0f, 1f)).rg;
}

void fragment() {
	float n = GetNoise(worldV);
	n -= texture(fadeCurve, vec2(UV.y, 0f)).r;
	n = clamp(n, 0f, 1f);
	
	vec3 normal = GetNormal(worldV);
	float dir = (UV.y - .5f) * 2f;
	normal.y -= dir * texture(fadeNormalCurve, vec2(UV.y, 0f)).r;
	
	normal = normalize(normal);
	float d = dot(normal, normalize(lightDirection)) * dotMultiply;
	d = d * .5f + .5f;
	
	float dither = texture(ditheringTexture, worldV / ditheringSize).r * 2f - 1f;
	d += dither * ditheringInfluence;
	
	d = clamp(d, 0f, 1f);
	
	d = floor(d * dotSteps) / dotSteps;
	
	COLOR *= texture(lightGradient, vec2(d, 0f));
	COLOR.a *= step(noiseThreshold, n);
}






