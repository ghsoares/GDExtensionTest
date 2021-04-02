extends Node2D

class_name PlanetDebug

var mouseDragging: bool = false

var planet
var desiredCameraPos: Vector2
var desiredCameraZoom: float

var debugging = true

func _ready() -> void:
	desiredCameraPos = Vector2(2048, 32.0)
	
	desiredCameraZoom = 1.0
	
	z_index = VisualServer.CANVAS_ITEM_Z_MAX

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_WHEEL_UP:
				desiredCameraZoom -= .1
			if event.button_index == BUTTON_WHEEL_DOWN:
				desiredCameraZoom += .1
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				mouseDragging = true
			else:
				mouseDragging = false
		desiredCameraZoom = clamp(desiredCameraZoom, .1, 1.0)
	if event is InputEventMouseMotion:
		if mouseDragging:
			desiredCameraPos -= event.relative * desiredCameraZoom

func _physics_process(delta: float) -> void:
	if planet.generating: return
	var camera = planet.camera
	if debugging:
		camera.desiredZoom = desiredCameraZoom
		camera.desiredPosition = desiredCameraPos
	else:
		desiredCameraZoom = camera.desiredZoom
		desiredCameraPos = camera.desiredPosition





