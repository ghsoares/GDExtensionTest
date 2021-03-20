shader_type canvas_item;

uniform sampler2D terrainHeightMap;
uniform vec2 terrainSize;
uniform float terrainResolution;

uniform sampler2D terrainTexture;
uniform sampler2D terrainGradient;
uniform float terrainTextureTiling = 256.0;
uniform float terrainTextureDisplacementTiling = 512.0;
uniform float terrainTextureDisplacement = 16.0;
uniform float terrainTextureEaseCurve = -2.0;
uniform float terrainTextureAdd = 0.0;
uniform float terrainTextureSteps = 8.0;
uniform vec2 terrainFadeRange = vec2(64, 256);
uniform vec3 terrainFadeAmount = vec3(0.0, .1, .2);

varying vec2 v;

float Ease(float x, float c) {return x;}

float SampleHeight() {return terrainSize.y * .5;}

float GetTerrainY() {return terrainSize.y - SampleHeight();}

void vertex() {
	v = VERTEX;
}

void TerrainColor(inout vec4 col) {
	float terrainOffset = v.y - GetTerrainY();
	
	vec2 terrainTextureSize = vec2(textureSize(terrainTexture, 0));
	
	float disp = texture(terrainTexture, v / terrainTextureDisplacementTiling).r * radians(360.0);
	vec2 dispVec = vec2(cos(disp), sin(disp)) * terrainTextureDisplacement;
	
	vec2 uv = v / terrainTextureTiling + dispVec / terrainTextureSize;
	float n = texture(terrainTexture, uv).r + terrainTextureAdd;
	
	float t1 = clamp(terrainOffset / terrainFadeRange.x, 0.0, 1.0);
	float t2 = clamp((terrainOffset - terrainFadeRange.x) / (terrainFadeRange.y - terrainFadeRange.x), 0.0, 1.0);
	
	float fade = mix(terrainFadeAmount.x, terrainFadeAmount.y, t1);
	fade = mix(fade, terrainFadeAmount.z, t2);
	
	n -= fade;
	
	n = Ease(n, terrainTextureEaseCurve);
	
	n = round(n * terrainTextureSteps) / terrainTextureSteps;
	n = clamp(n, 0.0, 1.0);
	
	col = texture(terrainGradient, vec2(n, 0.0));
}

void fragment() {
	TerrainColor(COLOR);
	
	COLOR.a *= step(GetTerrainY(), v.y);
}





