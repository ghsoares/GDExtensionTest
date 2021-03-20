shader_type canvas_item;

uniform sampler2D terrainHeightMap;
uniform vec2 terrainSize;
uniform float terrainResolution;

uniform float grassAmount = 1.0;
uniform float grassHeight = 16.0;
uniform sampler2D grassTexture;
uniform sampler2D grassGradient;

varying vec2 v;

float SampleHeight() {return terrainSize.y * .5;}

float GetTerrainY() {return terrainSize.y - SampleHeight();}

void vertex() {
	v = VERTEX;
}

void fragment() {
	float grassWidth = vec2(textureSize(grassTexture, 0)).r;
	float terrainY = GetTerrainY();
	float terrainDiff = terrainY - v.y;
	
	float grassH = texture(grassTexture, vec2(v.x / grassWidth, 0.0)).r * grassHeight;
	float t = terrainDiff / grassH;
	
	COLOR *= texture(grassGradient, vec2(t, 0.0));
	
	COLOR.a *= step(0.0, terrainDiff) * step(terrainDiff, grassH);
}










