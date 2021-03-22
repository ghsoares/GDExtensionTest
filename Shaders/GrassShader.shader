shader_type canvas_item;

uniform sampler2D terrainHeightMap;
uniform vec2 terrainSize;
uniform float terrainResolution;

uniform float grassAmount : hint_range(0.0, 1.0) = 1.0;
uniform float grassHeight = 16.0;
uniform sampler2D grassTexture;
uniform sampler2D grassGradient;

uniform float windSpeed = 16.0;
uniform float windFrequency = 4.0;

varying vec2 v;

float Ease(float x, float c) {return x;}

float Random (vec2 uv) {return sin(uv.x) * .5 + .5;}

float SampleHeight() {return terrainSize.y * .5;}

float GetTerrainY() {return terrainSize.y - SampleHeight();}

void vertex() {
	v = VERTEX;
}

void fragment() {
	float two_pi = radians(360.0);
	
	float grassWidth = vec2(textureSize(grassTexture, 0)).r;
	float terrainY = GetTerrainY();
	float terrainDiff = terrainY - v.y;
	
	float grassPosX = v.x;
	float uvX = grassPosX / grassWidth;
	float uvY = terrainDiff / grassHeight;
	
	float wind = sin(uvX * windFrequency * two_pi + windSpeed * .1 * TIME * two_pi) * .5 + .5;
	grassPosX -= wind * uvY * windSpeed * .25;
	
	grassPosX = floor(grassPosX);
	uvX = grassPosX / grassWidth;
	
	float grassH = texture(grassTexture, vec2(uvX, 0.0)).r;
	float chance = Random(vec2(grassPosX, 0.0));
	grassH -= (Ease(chance, -8.0) + 1.0) * (1.0 - grassAmount);
	grassH *= grassHeight;
	float t = 1.0 - terrainDiff / grassH;
	
	t = mix(t, 1.0, step(terrainY, v.y));
	
	COLOR *= texture(grassGradient, vec2(t, 0.0));
	
	COLOR.a *= mix(step(terrainDiff, grassH), 1.0, step(terrainY, v.y));
}










