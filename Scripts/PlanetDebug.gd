extends Node2D

class_name PlanetDebug

var mouseDragging: bool = false

var planet
var desiredCameraPos: Vector2
var desiredCameraZoom: float
var casterDirection: Vector2

var debugging = false

func _ready() -> void:
	desiredCameraPos = Vector2(2048, 32.0)
	
	desiredCameraZoom = 1.0
	casterDirection = Vector2(1.0, 1.0).normalized()
	
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

func _process(delta: float) -> void:
	var turn = Input.get_action_strength("rotate_right") - Input.get_action_strength("rotate_left")
	casterDirection = casterDirection.rotated(turn * PI * 2.0 * delta)
	update()

func _draw() -> void:
#	draw_circle(desiredCameraPos, 4.0, Color.yellow)
#	draw_line(desiredCameraPos, desiredCameraPos + casterDirection * 8, Color.yellow, 4.0)
#	var terrain: Terrain = planet.terrain
#	var cast = terrain.RayIntersect(desiredCameraPos, casterDirection)
#	if cast:
#		var p = cast.point
#		draw_line(desiredCameraPos, p, Color.green, 2.0)
#		draw_circle(p, 4.0, Color.green)
	
	
	
	pass




