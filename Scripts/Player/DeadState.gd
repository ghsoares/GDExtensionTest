extends State

class_name PlayerDeadState

export (Gradient) var scoreFuelGradient

var queryReset = false
var resetting = false

func enter() -> void:
	root.mode = RigidBody2D.MODE_STATIC
	root.colShape.disabled = true
	
	PlayerStats.PerfectsStreakBreak()
	PlayerStats.fuel -= 50.0
	
	root.spr.hide()
	root.speedPivot.hide()
	root.explosionParticleSystem.Explode()
	root.explosionParticlesParticleSystem.Explode()
	
	queryReset = false
	resetting = false
	
	root.world.camera.Shake(0.5, 48.0, 1000.0)
	root.world.game.Explosion(root.global_position, 256.0, 20.0, 4, .5)
	root.scoreParticlesParticleSystem.EmitParticle({
		"text": "-50 Fuel",
		"gradient": scoreFuelGradient
	})

func process() -> void:
	queryReset = Input.is_action_just_pressed("reset_level")

func physics_process() -> void:
	if queryReset and !resetting:
		Transition.Animate()
		resetting = true
	if resetting and !Transition.animating:
		root.global_transform = root.startTransform
		queryState("Hover")
		Transition.Animate(true)

func exit() -> void:
	root.linear_velocity = Vector2.ZERO
	root.angular_velocity = 0.0
	root.mode = RigidBody2D.MODE_RIGID
	
	root.colShape.disabled = false
	root.spr.show()
	root.speedPivot.show()
	
	root.world.camera.Warp(root.global_position)
