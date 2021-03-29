extends State

var resetting := false
var reset := false

func enter() -> void:
	var camera: GameCamera = root.planet.camera
	
	root.linear_velocity = Vector2.ZERO
	root.angular_velocity = 0.0
	
	root.body.hide()
	root.col.disabled = true
	root.mode = RigidBody2D.MODE_STATIC
	
	resetting = false
	reset = false
	
	root.explosionParticleSystem.Explosion()
	camera.desiredZoom = root.platformZoomRange.y

func physics_process() -> void:
	if Input.is_action_just_pressed("reset_level"):
		Transition()
	if reset:
		stateMachine.queryState("Hover")

func Transition() -> void:
	if resetting: return
	resetting = true
	Transition.FadeIn()
	yield(Transition, "FadeFinished")
	reset = true
	Transition.FadeOut()

func exit() -> void:
	root.linear_velocity = Vector2.ZERO
	root.angular_velocity = 0.0
	
	root.global_transform = root.startTransform
	root.body.show()
	root.col.disabled = false
	root.mode = RigidBody2D.MODE_RIGID

