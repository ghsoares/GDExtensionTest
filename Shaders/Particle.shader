shader_type canvas_item;

uniform sampler2D ditheringMatrix;
uniform float ditherScale = 1f;

void fragment() {
	COLOR *= texture(TEXTURE, UV);
	
	float d = distance(UV, vec2(.5f)) / .5f;
	
	vec2 ditheringSize = vec2(textureSize(ditheringMatrix, 0)) * ditherScale;
	vec2 scSize = 1f / SCREEN_PIXEL_SIZE;
	
	vec2 ratio = scSize / ditheringSize;
	vec2 ditheringUv = ratio * SCREEN_UV;
	
	float b = COLOR.a + texture(ditheringMatrix, ditheringUv).r;
	b = step(1f, b);
	
	COLOR.a = b;
	COLOR.a *= step(d, 1.0);
	COLOR.a *= step(UV.x, 1.0);
	COLOR.a *= step(0.0, UV.y);
}