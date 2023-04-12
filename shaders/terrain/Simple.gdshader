shader_type spatial;
render_mode unshaded;

#include "res://shaders/Terrain.gdshaderinc"

uniform sampler2D noise_color: source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D gradient_color: source_color, repeat_disable;
uniform sampler2D gradient_ground: source_color, repeat_disable;
uniform vec2 noise_size = vec2(1.0);
uniform float noise_tiling = 256.0;
uniform float noise_steps = 8.0;
uniform float ground_fade = 256.0;
uniform float ground_min = -1.0;
uniform float ground_max = 1.0;

varying vec4 pos;

TEXTURE_BICUBIC_DEFINE(noiseTextureBicubic)

void vertex() {
	pos = (transform * vec4(VERTEX, 1.0));
}

void fragment() {
	float a = sample_terrain(UV);
	ALPHA = step(a, 0.0);
	
	float n = noiseTextureBicubic(noise_color, (pos.xy / noise_tiling) * noise_size, noise_size).r;
	float fade = clamp(1.0 + a / ground_fade, 0.0, 1.0);
	fade = texture(gradient_ground, vec2(fade)).r;
	n += mix(ground_min, ground_max, fade);
	n = floor(n * noise_steps) / noise_steps;
	
	vec4 c = texture(gradient_color, vec2(n));
	
	ALBEDO = c.xyz;
	
	float sqa = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	
	vec4 square = vec4(
		1.0, 0.0, 0.0, 
		step(sqa - 0.01, 0.0)
	);
	
	ALBEDO.xyz = mix(ALBEDO.xyz, square.xyz, square.a);
	ALPHA = mix(ALPHA, square.a, square.a);
	
	ALPHA *= transparency;
}






