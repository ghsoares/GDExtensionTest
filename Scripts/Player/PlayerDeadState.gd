extends State

func enter() -> void:
	var camera: GameCamera = root.planet.camera
	
	root.linear_velocity = Vector2.ZERO
	root.angular_velocity = 0.0
	
	root.body.hide()
	root.col.disabled = true
	root.mode = RigidBody2D.MODE_STATIC
	
	root.explosionParticleSystem.Explosion()
	camera.desiredZoom = root.platformZoomRange.y

func physics_process() -> void:
	if Input.is_action_just_pressed("reset_level"):
		stateMachine.queryState("Hover")

func exit() -> void:
	root.linear_velocity = Vector2.ZERO
	root.angular_velocity = 0.0
	
	root.global_transform = root.startTransform
	root.body.show()
	root.col.disabled = false
	root.mode = RigidBody2D.MODE_RIGID

