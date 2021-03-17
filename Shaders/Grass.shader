shader_type canvas_item;

uniform sampler2D heightMap;
uniform sampler2D terrainGradient;
uniform float resolution;
uniform vec2 size;

uniform sampler2D grassTexture;
uniform vec2 grassHeight = vec2(4, 8);
uniform float grassTip = 1f;
uniform float grassTipSteps = 8.0;
uniform float grassAmount : hint_range(0f, 1f) = 1f;

uniform float windSpeed = 2f;
uniform float windFrequency = 2f;

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

void fragment() {
	vec2 pos = v;
	float height = sample_height(pos.x);
	float terrainY = size.y - height;
	float heightDiff = terrainY - pos.y;
	float maxGrassHeight = max(grassHeight.x, grassHeight.y);
	
	float grassSize = vec2(textureSize(grassTexture, 0)).x;
	float distortion = 0f;
	
	distortion += sin(TIME * -windSpeed * 1f + pos.x * radians(360f) * windFrequency);
	distortion = distortion * .5f + .5f;
	distortion *= (heightDiff / maxGrassHeight) * -windSpeed * .5f;
	
	float grassX = floor(pos.x + distortion);
	float grassUv = (pos.x + distortion) / grassSize;
	
	float h = texture(grassTexture, vec2(grassUv, 0f)).r;
	h = mix(grassHeight.x, grassHeight.y, h);
	
	float chance = random(vec2(grassX, 0f));
	float diff = (chance + 1f);
	diff = pow(diff, 2f);
	h -= diff * maxGrassHeight * (1f - grassAmount);
	
	float grassY = terrainY - h;
	
	if (pos.y < grassY) discard;
	
	vec4 col = texture(terrainGradient, vec2(1f, 0f));
	if (pos.y - grassY < grassTip) {
		float t = (pos.y - grassY) / grassTip;
		t = floor(t * grassTipSteps) / grassTipSteps;
		col = texture(terrainGradient, vec2(t, 0f));
	}
	
	COLOR *= col;
}



