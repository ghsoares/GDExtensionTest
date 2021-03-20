extends Node

var functions = {}
var compiledMaterials = {}

func _ready() -> void:
	InitFunctions()
	
	var materialsToCompile = {
		"Grass": preload("res://Materials/GrassMaterial.tres"),
		"Terrain": preload("res://Materials/TerrainMaterial.tres"),
	}
	for materialName in materialsToCompile.keys():
		var material = materialsToCompile[materialName]
		var shader = material.shader
		CompileShader(shader)
		compiledMaterials[materialName] = material

func InitFunctions() -> void:
	functions["float Ease(float x, float c)"] = "float Ease(float x, float c) {if (x < 0f) x = 0f;if (x > 1f) x = 1f;if (c > 0f) {if (c < 1f) {return 1f - pow(1f - x, 1f / c);} else {return pow(x, c);}} else if (c < 0f) {if (x < 0.5f) {return pow(x * 2f, -c) * .5f;} else {return (1f - pow(1f - (x - .5f) * 2f, -c)) * .5f + .5f;}}return 0f;}"
	functions["float SampleHeight()"] = "float SampleHeight() {float x = v.x;float height1 = texture(terrainHeightMap, vec2(x, 0.0) / terrainSize).r;float height2 = texture(terrainHeightMap, vec2(x + 1.0/terrainResolution, 0.0) / terrainSize).r;float t = fract(x * terrainResolution);float h = mix(height1, height2, t);return h * terrainSize.y;}"

func CompileShader(shader: Shader) -> void:
	var shaderCode = shader.code
	var shaderLines = shaderCode.split("\n")
	
	for i in range(shaderLines.size()):
		var line :String= shaderLines[i]
		
		for functionSignature in functions:
			if line.begins_with(functionSignature):
				line = functions[functionSignature]
		
		shaderLines[i] = line
	
	shaderCode = shaderLines.join("\n")
	shader.code = shaderCode

func GetMaterial(name: String) -> ShaderMaterial:
	return compiledMaterials[name]




