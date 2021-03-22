extends HeightmapRigidbody2D

onready var body := $Body
onready var col := $Col
onready var stateMachine := $StateMachine

onready var thrusterParticleSystem := $Particles/Thruster
onready var groundParticleSystem := $Particles/GroundThruster

export (float) var maxSafeVelocity = 32.0
export (float) var maxSafeAngle = 5.0

var startTransform: Transform2D

func _ready() -> void:
	._ready()
	if !planet:
		stateMachine.set_process(false)
		stateMachine.set_physics_process(false)
		set_process(false)
		set_physics_process(false)
		remove_child(thrusterParticleSystem)
		remove_child(groundParticleSystem)
	else:
		groundParticleSystem.planet = planet
	
	startTransform = global_transform
	
	stateMachine.root = self
	stateMachine.start()

func _physics_process(delta: float) -> void:
	var camera: GameCamera = planet.camera
	camera.desiredPosition = global_position
	pass
