extends Control

onready var view := $View
onready var planet := $View/Planet
onready var zoomCamera := $ZoomCamera

func _ready() -> void:
	connect("resized", self, "UpdateViewport")
	UpdateViewport()

func _process(delta: float) -> void:
	if planet.generating: return
	
	var camera :GameCamera= planet.camera
	var cameraScPos = camera.get_global_transform_with_canvas().origin
	
	cameraScPos.x = floor(cameraScPos.x)
	cameraScPos.y = floor(cameraScPos.y)
	
	var zoom = camera.currentZoom
	
	zoomCamera.zoom = Vector2.ONE * zoom
	zoomCamera.position = cameraScPos
	
	zoomCamera.force_update_scroll()

func UpdateViewport() -> void:
	view.size = rect_size

func _input(event: InputEvent) -> void:
	view.input(event)


