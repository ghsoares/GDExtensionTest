extends HeightmapRigidbody2D

onready var body := $Body
onready var col := $Col
onready var stateMachine := $StateMachine

onready var thrusterParticleSystem := $Particles/Thruster
onready var waterThrusterParticleSystem := $Particles/WaterThruster
onready var groundParticleSystem := $Particles/GroundThruster
onready var waterGroundParticleSystem := $Particles/WaterGroundThruster
onready var explosionParticleSystem := $Particles/Explosion
onready var windParticleSystem := $Particles/Wind

export (float) var maxSafeVelocity = 32.0
export (float) var maxSafeAngle = 5.0
export (float) var minPerfectVelocity = 4.0
export (float) var minPerfectAngle = 1.0
export (Vector2) var platformDistanceRange = Vector2(32.0, 100.0)
export (Vector2) var platformZoomRange = Vector2(.5, 1.0)

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
		waterGroundParticleSystem.planet = planet
	
	startTransform = global_transform
	startTransform.origin.y = 64.0
	
	stateMachine.root = self
	stateMachine.start()

func _physics_process(delta: float) -> void:
	var camera: GameCamera = planet.camera
	camera.desiredPosition = global_position
	if !planet.generating:
		groundParticleSystem.AddForce(Vector2.RIGHT * planet.windSpeed * 2.0)
		explosionParticleSystem.AddForce(Vector2.RIGHT * planet.windSpeed * 2.0)

func GetPlatformZoom() -> float:
	var platformPlacer = planet.terrain.platformsPlacer
	var platform :Platform= platformPlacer.GetNearest(global_position.x)
	
	var distance = (platform.global_position - global_position).length()
	var t = inverse_lerp(platformDistanceRange.x, platformDistanceRange.y, distance)
	var z = lerp(platformZoomRange.x, platformZoomRange.y, clamp(t, 0.0, 1.0))
	return z



