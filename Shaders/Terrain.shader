shader_type canvas_item;

uniform sampler2D heightMap;
uniform float resolution;
uniform vec2 size;

uniform sampler2D text;
uniform sampler2D gradient;
uniform float textureEasing = 1f;
uniform float textureTiling = 128f;
uniform float warpTiling = 256f;
uniform float warpAmount = 1f;
uniform float textureSteps = 8f;

uniform vec2 fadeRange = vec2(32f, 256f);
uniform vec3 fadeValues = vec3(1f, .5f, 0f);

varying vec2 v;

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

void main_color(vec2 pos, inout vec4 col) {
	vec2 uv = pos / textureTiling;
	float height = sample_height(pos.x);
	float terrainY = size.y - height;
	float heightDiff = height - (size.y - pos.y);
	
	vec2 texturePixelSize = 1f / vec2(textureSize(text, 0));
	
	float warp = (texture(text, pos / warpTiling).r * 2f - 1f) * 3.1415;
	uv += vec2(cos(warp), sin(warp)) * warpAmount * texturePixelSize;
	
	float t = texture(text, uv).r;
	
	t = ease(t, textureEasing);
	
	if (heightDiff < fadeRange.x) {
		float fadeT = heightDiff / fadeRange.x;
		fadeT = clamp(fadeT, 0, 1);
		t += mix(fadeValues.x, fadeValues.y, fadeT);
	} else {
		float fadeT = (heightDiff - fadeRange.x) / (fadeRange.y - fadeRange.x);
		fadeT = clamp(fadeT, 0, 1);
		t += mix(fadeValues.y, fadeValues.z, fadeT);
	}
	
	t = floor(t * textureSteps) / textureSteps;
	
	t = clamp(t, 0, 1);
	
	vec4 thisCol = texture(gradient, vec2(t, 0f));
	thisCol.a *= step(terrainY, pos.y);
	
	col = mix(col, thisCol, thisCol.a);
}

void fragment() {
	vec2 pos = v;
	
	vec4 col = vec4(0.0);
	
	main_color(pos, col);
	
	COLOR = col;
}





