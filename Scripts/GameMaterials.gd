extends Node

var functions = {}
var compiledMaterials = {}

func _ready() -> void:
	InitFunctions()
	CompileMaterialsPath("Materials/Planets")

func InitFunctions() -> void:
	functions["float Ease(float x, float c)"] = "float Ease(float x, float c) {if (x < 0f) x = 0f;if (x > 1f) x = 1f;if (c > 0f) {if (c < 1f) {return 1f - pow(1f - x, 1f / c);} else {return pow(x, c);}} else if (c < 0f) {if (x < 0.5f) {return pow(x * 2f, -c) * .5f;} else {return (1f - pow(1f - (x - .5f) * 2f, -c)) * .5f + .5f;}}return 0f;}"
	functions["float SampleHeight()"] = "float SampleHeight() {float x = v.x;float height1 = texture(terrainHeightMap, vec2(x, 0.0) / terrainSize).r;float height2 = texture(terrainHeightMap, vec2(x + 1.0/terrainResolution, 0.0) / terrainSize).r;float t = fract(x * terrainResolution);float h = mix(height1, height2, t);return h * terrainSize.y;}"
	functions["float Random(vec2 uv)"] = "float Random (vec2 uv) {return fract(sin(dot(uv.xy,vec2(12.9898,78.233))) * 43758.5453123);}"

func CompileMaterialsPath(path: String) -> void:
	var dir : Directory = Directory.new()
	if dir.open("res://" + path) == OK:
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				var newPath = path.split("/")
				newPath.append(file_name)
				CompileMaterialsPath(newPath.join("/"))
			else:
				var fullPath = path.split("/")
				fullPath.append(file_name)
				fullPath = fullPath.join("/")
				var materialName = fullPath.replace("Materials/", "").replace("Material.tres", "")
				var material = load(fullPath) as ShaderMaterial
				if material:
					var shader = material.shader
					print("Compiling material " + materialName)
					CompileShader(shader)
					print("Material compiled!")
					compiledMaterials[materialName] = material
			file_name = dir.get_next()

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
	if !compiledMaterials.has(name):
		print("Compiling material " + name)
		var material = load("res://Materials/" + name + "Material.tres") as ShaderMaterial
		if !material:
			push_error("Couldn't find material with name " + name)
			return null
		var shader = material.shader
		CompileShader(shader)
		compiledMaterials[name] = material
		print("Material compiled!")
	return compiledMaterials[name]





