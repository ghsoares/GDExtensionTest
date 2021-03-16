extends Camera2D

class_name WorldCamera

var desiredPosition : Vector2
var pos : Vector2
var noise : OpenSimplexNoise

var currentShake = {
	"time": 0.0,
	"startTime": 0.0,
	"magnitude": 0.0,
	"frequency": 0.0
}

const MAX_CAMERA_SHAKE = 64.0

export (float) var lerpingSpeed = 8.0

func _init() -> void:
	current = true
	process_mode = Camera2D.CAMERA2D_PROCESS_PHYSICS
	limit_smoothed = true
	noise = OpenSimplexNoise.new()
	noise.seed = randi()

func _ready() -> void:
	desiredPosition = global_position
	pos = global_position

func _process(delta: float) -> void:
	var desiredOffset = Vector2.ZERO
	
	if currentShake.time > 0.0:
		var passed = currentShake.startTime - currentShake.time
		var t = currentShake.time / currentShake.startTime
		var posX = noise.get_noise_2d(passed * currentShake.frequency, 0.0)
		var posY = noise.get_noise_2d(0.0, passed * currentShake.frequency)
		desiredOffset = Vector2(posX, posY) * currentShake.magnitude * t
		currentShake.time -= delta
	else:
		currentShake = {
			"time": 0.0,
			"startTime": 0.0,
			"magnitude": 0.0,
			"frequency": 0.0
		}
	
	offset = desiredOffset

func Warp(toPosition: Vector2) -> void:
	desiredPosition = toPosition
	pos = toPosition

func Shake(time: float, magnitude: float, frequency: float) -> void:
	magnitude = clamp(magnitude, 0.0, MAX_CAMERA_SHAKE)
	
	currentShake.time = max(currentShake.time, time)
	currentShake.startTime = max(currentShake.startTime, time)
	currentShake.magnitude = max(currentShake.magnitude, magnitude)
	currentShake.frequency = max(currentShake.frequency, frequency)

func _physics_process(delta: float) -> void:
	pos = pos.linear_interpolate(desiredPosition, clamp(delta * lerpingSpeed, 0, 1))
	global_position = pos






