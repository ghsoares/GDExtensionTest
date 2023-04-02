
#define CUBIC(a, b, c, d, t) (0.5 * ((b * 2.0) + (-a + c) * t + (2.0 * a - 5.0 * b + 4.0 * c - d) * (t * t) + (-a + 3.0 * b - 3.0 * c + d) * (t * t * t)))
#define BICUBIC(a0, b0, c0, d0, a1, b1, c1, d1, a2, b2, c2, d2, a3, b3, c3, d3, tx, ty) (CUBIC(\
	CUBIC(a0, b0, c0, d0, tx), \
	CUBIC(a1, b1, c1, d1, tx), \
	CUBIC(a2, b2, c2, d2, tx), \
	CUBIC(a3, b3, c3, d3, tx), \
	ty \
))

vec4 textureBicubic(sampler2D p_sample, vec2 p_uv, vec2 p_size) {
	vec2 pf = fract(p_uv);
	vec2 pi = floor(p_uv);
	pi += 0.5;
	
	vec4 s00 = texture(p_sample, vec2(pi.x - 1.0, pi.y - 1.0) / p_size);
	vec4 s01 = texture(p_sample, vec2(pi.x - 1.0, pi.y - 0.0) / p_size);
	vec4 s02 = texture(p_sample, vec2(pi.x - 1.0, pi.y + 1.0) / p_size);
	vec4 s03 = texture(p_sample, vec2(pi.x - 1.0, pi.y + 2.0) / p_size);
	
	vec4 s10 = texture(p_sample, vec2(pi.x - 0.0, pi.y - 1.0) / p_size);
	vec4 s11 = texture(p_sample, vec2(pi.x - 0.0, pi.y - 0.0) / p_size);
	vec4 s12 = texture(p_sample, vec2(pi.x - 0.0, pi.y + 1.0) / p_size);
	vec4 s13 = texture(p_sample, vec2(pi.x - 0.0, pi.y + 2.0) / p_size);
	
	vec4 s20 = texture(p_sample, vec2(pi.x + 1.0, pi.y - 1.0) / p_size);
	vec4 s21 = texture(p_sample, vec2(pi.x + 1.0, pi.y - 0.0) / p_size);
	vec4 s22 = texture(p_sample, vec2(pi.x + 1.0, pi.y + 1.0) / p_size);
	vec4 s23 = texture(p_sample, vec2(pi.x + 1.0, pi.y + 2.0) / p_size);
	
	vec4 s30 = texture(p_sample, vec2(pi.x + 2.0, pi.y - 1.0) / p_size);
	vec4 s31 = texture(p_sample, vec2(pi.x + 2.0, pi.y - 0.0) / p_size);
	vec4 s32 = texture(p_sample, vec2(pi.x + 2.0, pi.y + 1.0) / p_size);
	vec4 s33 = texture(p_sample, vec2(pi.x + 2.0, pi.y + 2.0) / p_size);
	
	return BICUBIC(s00, s10, s20, s30, s01, s11, s21, s31, s02, s12, s22, s32, s03, s13, s23, s33, pf.x, pf.y);
}








