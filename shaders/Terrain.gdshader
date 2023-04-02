shader_type spatial;
render_mode unshaded;

#include "Common.gdshaderinc"

#define BICUBIC_SAMPLING

uniform sampler2D terrain_texture : source_color, filter_linear;
uniform vec2 terrain_size = vec2(4.0);

void fragment() {
	vec2 uv = UV;
	uv.y = 1.0 - uv.y;
	vec2 texSize = terrain_size + 3.0;
	vec2 pix = uv * terrain_size + 1.0;
	
	#ifdef BICUBIC_SAMPLING
	float f = textureBicubic(terrain_texture, pix, texSize).r;
	#else
	float f = texture(terrain_texture, pix / texSize).r;
	#endif
	
	// f = smoothstep(0.1, -0.1, f);
	
	ALPHA = step(f, 0.0);
	ALBEDO = vec3(fract(f / 8.0));
	
	float b = min(UV.x, 1.0 - UV.x);
	b = min(b, min(UV.y, 1.0 - UV.y));
	b = step(b, 0.01);
	
	ALPHA = max(ALPHA, b);
	ALBEDO = mix(ALBEDO, vec3(1.0, 0.0, 0.0), b);
}




