shader_type canvas_item;

uniform sampler2D heightMap;
uniform float resolution;
uniform vec2 size;

uniform sampler2D text;
uniform float tiling = 128f;
uniform float warpTiling = 256f;
uniform float warpAmnt = 32f;
uniform float easing = -2f;

uniform vec2 fadeRange = vec2(32f, 256f);
uniform vec3 fadeValues = vec3(1f, .5f, 0f);

uniform float threshold : hint_range(.0, 1) = .5f;
uniform float width : hint_range(.0, 1) = .25f;

uniform float widthDistortionTiling = 128f;
uniform float widthDistortionMagnitude : hint_range(0f, 1f) = .01f;
uniform float widthDistortionFrequency = 2f;
uniform float widthDistortionSpacing = 2f;

uniform sampler2D gradient;

uniform float steps = 8f;

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

void fragment() {
	vec2 pos = v;
	float height = sample_height(pos.x);
	float heightDiff = pos.y - (size.y - height);
	
	if (heightDiff < 0f) discard;
	
	vec2 textPixelSize = 1f / vec2(textureSize(text, 0));
	
	vec2 uv = pos / tiling;
	float n = texture(text, pos / warpTiling).r * radians(180f);
	
	uv += vec2(cos(n), sin(n)) * warpAmnt * textPixelSize;
	
	n = texture(text, uv).r;
	n = ease(n, easing);
	
	float w = width;
	float dist = texture(text, pos / widthDistortionTiling).r;
	dist = sin((dist * widthDistortionSpacing + TIME * widthDistortionFrequency) * radians(360f));
	w += dist * widthDistortionMagnitude;
	w = max(w, 0f);
	
	n = 1f - abs(n - threshold) / (w * .5f);
	
	if (heightDiff < fadeRange.x) {
		float fadeT = heightDiff / fadeRange.x;
		n += mix(fadeValues.x, fadeValues.y, fadeT);
	} else {
		float fadeT = (heightDiff - fadeRange.x) / (fadeRange.y - fadeRange.x);
		fadeT = clamp(fadeT, 0, 1);
		n += mix(fadeValues.y, fadeValues.z, fadeT);
	}
	
	n = floor(n * steps) / steps;
	
	n = clamp(n, 0, 1);
	
	vec4 col = texture(gradient, vec2(n));
	
	COLOR = col;
}



