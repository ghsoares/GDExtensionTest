#include "Common.gdshaderinc"

uniform sampler2D terrain_texture : source_color, filter_linear;
uniform vec2 terrain_size = vec2(4.0);
uniform float transparency = 1.0;
uniform mat4 transform;

float sample_terrain(vec2 uv) {
	uv.y = 1.0 - uv.y;
	vec2 texSize = terrain_size + 3.0;
	vec2 pix = uv * terrain_size + 1.0;
	
	#ifdef SAMPLE_LINEAR
	float f = texture(terrain_texture, pix / texSize).r;
	#else
	float f = textureBicubic(terrain_texture, pix, texSize).r;
	#endif
	// f = -1.0;
	
	return f;
}




