shader_type canvas_item;

uniform sampler2D grassHeightMap;
uniform sampler2D grassAmountNoise;
uniform sampler2D gradient;
uniform float grassHeightMapSize = 64f;
uniform float grassAmountNoiseSize = 512f;
uniform float grassAmountHeightMapCurve = -2f;
uniform float grassAmountNoiseCurve = -2f;
uniform float grassAmount : hint_range(0f, 1f) = 1f;
uniform vec2 size = vec2(4096f, 16f);

uniform float windSpeed = 4f;
uniform float windFrequency = 32f;
uniform mat4 playerTransform;
uniform float playerDistortionDistance = 32f;
uniform float playerDistortionAmount = 16f;
uniform float playerThrusterPercentage = 1f;
uniform float playerThrusterLength = 32f;
uniform vec2 playerThrusterAngleRange = vec2(30f);
uniform float playerThrusterDistortionAmount = 64f;
uniform float playerThrusterDistortionSpeed = 2f;
uniform float playerThrusterDistortionFrequency = 2f;

varying vec2 v;
varying vec2 localV;
varying float time;

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

float cross2D(vec2 v1, vec2 v2) {
	return v1.x * v2.y - v1.y * v2.x;
}

float angle_between(vec2 v1, vec2 v2) {
	return atan(cross2D(v1, v2), dot(v1, v2));
}

void vertex() {
	v = UV;
	v.y = (v.y - .5f) * 2f;
	v *= size;
	
	localV = VERTEX;
	time = TIME;
}

vec2 CalculatePlayerDistortion(vec2 pos) {
	vec2 playerPos = playerTransform[3].xy;
	vec2 playerUp = -normalize(playerTransform[1].xy);
	vec2 playerDiff = (localV - playerPos);
	playerDiff.y = max(playerDiff.y, 0f);
	float playerDistance = length(playerDiff);
	float distT = 1f - clamp(playerDistance / playerDistortionDistance, 0f, 1f);
	distT = Ease(distT, -2f);
	
	vec2 dist = vec2(0f, 1f) * distT * playerDistortionAmount;
	
	float thrusterAngle = abs(angle_between(-playerUp, normalize(playerDiff)));
	//float thrusterT = 1f - clamp(thrusterAngle / radians(playerThrusterAngle), 0f, 1f);
	float thrusterT = (thrusterAngle - radians(playerThrusterAngleRange.x)) / (radians(playerThrusterAngleRange.y) - radians(playerThrusterAngleRange.x));
	thrusterT = 1f - clamp(thrusterT, 0f, 1f);
	vec2 thrusterDistortion = vec2(0f, 1f) * thrusterT * playerThrusterDistortionAmount * playerThrusterPercentage;
	float s = sin(abs(playerDiff.x) * playerThrusterDistortionFrequency * -radians(360f) + playerThrusterDistortionSpeed * radians(360f) * time);
	thrusterDistortion *= mix(.0f, 1f, s * .5f + .5f);
	thrusterDistortion *= 1f - clamp(playerDistance / playerThrusterLength, 0f, 1f);
	dist += thrusterDistortion;
	
	dist *= step(0f, pos.y);
	
	return dist;
}

void fragment() {
	float pi = radians(360f);
	vec2 pos = v;
	
	vec2 dist = CalculatePlayerDistortion(pos);
	pos += dist.xy;
	
	float wind = sin(pos.x * pi * (windFrequency * .01f) + windSpeed * time) * .5 + .5;
	pos.x += wind * (windSpeed * .02f) * pos.y;
	
	float h = texture(grassHeightMap, pos.xx / grassHeightMapSize).r;
	h = Ease(h, grassAmountHeightMapCurve);
	
	float nUv = pos.x / grassAmountNoiseSize;
	float amnt = texture(grassAmountNoise, vec2(nUv)).r;
	amnt = Ease(amnt, grassAmountNoiseCurve);
	amnt -= 1f;
	amnt += grassAmount * 2f;
	
	h *= clamp(amnt, 0, 1) * size.y;
	
	float t = pos.y / h;
	
	COLOR *= texture(gradient, vec2(t));
	COLOR.a *= step(t, 1f);
}