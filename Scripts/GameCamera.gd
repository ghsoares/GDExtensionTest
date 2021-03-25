extends Camera2D

class_name GameCamera

var desiredZoom: float
var desiredPosition: Vector2

var currentZoom: float

func _ready() -> void:
	process_mode = Camera2D.CAMERA2D_PROCESS_PHYSICS
	current = true
	
	desiredZoom = 1.0
	desiredPosition = global_position
	
	currentZoom = desiredZoom

func _physics_process(delta: float) -> void:
	visible = current
	if !visible: return
	
	desiredPosition.x = clamp(desiredPosition.x, limit_left, limit_right)
	desiredPosition.y = clamp(desiredPosition.y, limit_top, limit_bottom)
	
	global_position = global_position.linear_interpolate(desiredPosition, clamp(delta * 8.0, 0.0, 1.0))
	#global_position.x = floor(global_position.x)
	#global_position.y = floor(global_position.y)
	
	force_update_scroll()
	
	currentZoom = lerp(currentZoom, desiredZoom, clamp(delta * 8.0, 0.0, 1.0))









