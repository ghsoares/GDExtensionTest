extends Control

onready var view := $View
onready var planet := $View/Planet
onready var screen := $Screen
onready var zoomCamera := $ZoomCamera

func _ready() -> void:
	connect("resized", self, "UpdateViewport")
	UpdateViewport()
	CompileShader()

func _process(delta: float) -> void:
	if planet.generating: return
	
	var camera :GameCamera= planet.camera
	var cameraScPos = camera.get_global_transform_with_canvas().origin
	
	#cameraScPos.x = floor(cameraScPos.x)
	#cameraScPos.y = floor(cameraScPos.y)
	
	var zoom = camera.currentZoom
	
	zoomCamera.zoom = Vector2.ONE * zoom
	zoomCamera.position = cameraScPos
	
	zoomCamera.force_update_scroll()

func UpdateViewport() -> void:
	view.size = rect_size

func _input(event: InputEvent) -> void:
	view.input(event)

func CompileShader() -> void:
	var shader :Shader= screen.material.shader
	var code = shader.code
	var lines = code.split("\n")
	
	for i in range(lines.size()):
		var line :String = lines[i]
		
		if line.begins_with("vec3 GetBloom"):
			var sizeExpr = RegEx.new()
			sizeExpr.compile("Kernel=(\\d)")
			var result = sizeExpr.search(line)
			if result:
				#line = CreateKernelFunction(float(result.get_string(1)))
				pass
		
		lines[i] = line
	
	shader.code = lines.join("\n")

func CreateKernelFunction(size: float = 3):
	var lines = PoolStringArray()
	size = floor(size / 2.0)
	lines.append("vec3 GetBloom(sampler2D tex, vec2 uv, vec2 texPixelSize) {")
	lines.append("vec3 bloom = vec3(0.0);")
	lines.append("vec2 off = vec2(" + str(size) + ") * texPixelSize;")
	var total = 0.0
	for x in range(-size, size+1):
		for y in range(-size, size+1):
			var off = Vector2(x, y)
			var dst = off.length()
			var t = 1.0 - clamp(dst / size, 0.0, 1.0)
			total += t
			if t == 1.0:
				t = "1.0"
			elif t == 0.0:
				t = "0.0"
			else:
				t = str(t)
			lines.append("bloom += GetBloomPixel(tex, uv + off * vec2" + str(off) + ") * " + t + ";")
	lines.append("bloom /= " + str(total) + ";")
	lines.append("return bloom;")
	lines.append("}")
	print(lines.size())
	return lines.join("\n")




