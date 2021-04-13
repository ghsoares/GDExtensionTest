shader_type canvas_item;

uniform float angle = 45f;
uniform float dropSize = 2f;
uniform float spacing;
uniform vec2 sizeRange = vec2(16f, 32f);
uniform vec2 tiling = vec2(512f, 512f);
uniform vec2 motion = vec2(0f, 1f);
uniform sampler2D dropGradient;
uniform sampler2D variancyGradient;
uniform sampler2D transitionGradient;
uniform float transitionLength = 32f;

varying vec2 v;

float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}

void vertex() {
	v = VERTEX;
}

void fragment() {
	float tg = tan(radians(angle));
	
	vec2 uv = vec2(v.x + v.y * tg, v.y);
	uv.x += motion.x * TIME;
	uv.x = floor(uv.x / dropSize) * dropSize;
	
	float nOff = random(vec2(uv.x, 0f)) * spacing;
	float maxRange = max(sizeRange.x, sizeRange.y);
	float nW = mix(sizeRange.x, sizeRange.y, random(vec2(uv.x, 1f)));
	nOff += motion.y * TIME;
	nOff += maxRange;
	nOff = fract(nOff / tiling.y) * tiling.y;
	nOff -= maxRange;
	
	float t = (uv.y - nOff) / nW;
	t = 1f - t;
	
	float vT = random(vec2(uv.x, 2f));
	float tT = clamp(v.y / transitionLength, 0f, 1f);
	
	vec4 col = texture(dropGradient, vec2(t, 0f));
	col *= texture(transitionGradient, vec2(tT, 0f));
	col *= texture(variancyGradient, vec2(vT, 0f));
	
	COLOR = col;
	COLOR.a *= step(0f, t);
	COLOR.a *= step(t, 1f);
}









