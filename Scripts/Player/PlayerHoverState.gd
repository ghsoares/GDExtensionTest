extends State

export (float) var maxAngularVelocity := 15.0
export (float) var maxVelocity := 128.0
export (float) var maxThrusterForce := 320.0
export (float) var thrusterAddRate := 10.0
export (float) var onWaterThrusterLossRate := .75
export (float) var angularAcceleration := 15.0
export (float) var velocityDrag := 8.0
export (float) var angularVelocityDrag := 8.0
export (float) var kickOffForceAdd := .5
export (float) var kickOffTime := .1
export (float) var thrusterDPS := 5.0

var bodiesInsideThruster := []
var currentThrusterForce = 0.0
var thrusterAdd = 0.0
var angAdd = 0.0
var startKickOff := false
var kickOff := false
var currKickOffTime := 0.0

func enter() -> void:
	currentThrusterForce = 0.0
	kickOff = false
	root.thrusterArea.connect("body_entered", self, "ThrusterAreaEnter")
	root.thrusterArea.connect("body_exited", self, "ThrusterAreaExit")
	root.speedFireParticleSystem.emitting = true
	bodiesInsideThruster = []

func physics_process() -> void:
	if startKickOff:
		startKickOff = false
	MotionProcess()
	CollisionProcess()
	ThrusterDamageProcess()
	CameraProcess()
	ParticlesProcess()

func MotionProcess() -> void:
	var forceMultiply = 1.0
	
	thrusterAdd = Input.get_action_strength("thruster_add") - Input.get_action_strength("thruster_subtract")
	angAdd = Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	
	if Input.is_action_just_pressed("thruster_add") and currentThrusterForce == 0.0:
		kickOff = true
		startKickOff = true
		currKickOffTime = kickOffTime
	
	if kickOff:
		thrusterAdd *= 1.0 + kickOffForceAdd
		forceMultiply *= 1.5
		currKickOffTime -= fixedDeltaTime
		if currKickOffTime <= 0.0 or Input.is_action_just_released("thruster_add"):
			kickOff = false
	
	if root.insideWater and !PlayerStats.hasWaterThruster:
		currentThrusterForce -= thrusterAddRate * onWaterThrusterLossRate * fixedDeltaTime
	currentThrusterForce += thrusterAdd * thrusterAddRate * fixedDeltaTime
	currentThrusterForce = clamp(currentThrusterForce, 0, maxThrusterForce)
	if PlayerStats.currentFuel == 0.0:
		currentThrusterForce = 0.0
	
	var thrusterT = currentThrusterForce / maxThrusterForce
	
	if root.insideWater and PlayerStats.hasWaterThruster:
		forceMultiply = 1.5
	
	if !root.insideWater:
		root.linear_velocity += Vector2.RIGHT * (root.planet.windSpeed / (1.0 + root.mass)) * fixedDeltaTime * 1.0
	
	root.linear_velocity += -root.global_transform.y * currentThrusterForce * forceMultiply * fixedDeltaTime / (1.0 + root.mass)
	root.angular_velocity += angAdd * angularAcceleration * fixedDeltaTime
	
	root.linear_velocity -= root.linear_velocity * clamp(velocityDrag * fixedDeltaTime, 0, 1)
	root.angular_velocity -= root.angular_velocity * clamp(angularVelocityDrag * fixedDeltaTime, 0, 1)
	
	root.angular_velocity = clamp(root.angular_velocity, -maxAngularVelocity, maxAngularVelocity)
	root.linear_velocity = root.linear_velocity.clamped(maxVelocity)
	
	#	PlayerStats.currentFuel -= PlayerStats.fuelLossRate * currentThrusterForce * fixedDeltaTime

func CollisionProcess() -> void:
	if root.collidedPoints.size() > 0:
		var platformPlacer = root.planet.terrain.platformsPlacer
		var platform :Platform= platformPlacer.GetNearest(root.global_position.x)
		
		var safeLanding = true
		
		if root.linear_velocity.length() > root.maxSafeVelocity:
			safeLanding = false
		if abs(root.rotation_degrees) > root.maxSafeAngle:
			safeLanding = false
			
		if safeLanding:
			for p in root.collisionPoints:
				var worldP = root.to_global(p)
				var dst = platform.GetDistance(worldP.x)
				if dst > 0.0:
					safeLanding = false
					break
					
		if safeLanding:
			stateMachine.queryState("Landed").platform = platform
		else:
			stateMachine.queryState("Dead")

func ThrusterDamageProcess() -> void:
	var thrusterT = currentThrusterForce / maxThrusterForce
	for body in bodiesInsideThruster:
		if body.is_in_group("Damageable") and thrusterT > .1:
			body.Damage(thrusterDPS * fixedDeltaTime * thrusterT)

func CameraProcess() -> void:
	var camera: GameCamera = root.planet.camera
	camera.desiredZoom = root.GetPlatformZoom()

func ParticlesProcess() -> void:
	if startKickOff:
		root.thrusterExplosionParticleSystem.Explode()
	
	var thrusterT = currentThrusterForce / maxThrusterForce
	
	if root.insideWater:
		root.speedFireParticleSystem.emitting = false
		root.windParticleSystem.windSpeed = 0.0
		if PlayerStats.hasWaterThruster:
			root.thrusterParticleSystem.rate = 0.0
			root.groundParticleSystem.rate = 0.0
			root.waterThrusterParticleSystem.rate = thrusterT * 32.0
			root.waterGroundParticleSystem.rate = thrusterT * 32.0
	else:
		root.speedFireParticleSystem.emitting = true
		root.windParticleSystem.windSpeed = root.planet.windSpeed
		root.thrusterParticleSystem.rate = thrusterT * 64.0
		root.groundParticleSystem.rate = thrusterT * 64.0
		root.waterThrusterParticleSystem.rate = 0.0
		root.waterGroundParticleSystem.rate = 0.0

func exit() -> void:
	root.speedFireParticleSystem.emitting = false
	root.thrusterParticleSystem.rate = 0.0
	root.groundParticleSystem.rate = 0.0
	root.waterGroundParticleSystem.rate = 0.0
	root.waterThrusterParticleSystem.rate = 0.0
	root.windParticleSystem.windSpeed = 0.0
	root.thrusterArea.disconnect("body_entered", self, "ThrusterAreaEnter")
	root.thrusterArea.disconnect("body_exited", self, "ThrusterAreaExit")

func ThrusterAreaEnter(body: Node2D) -> void:
	print(body)
	bodiesInsideThruster.append(body)

func ThrusterAreaExit(body: Node2D) -> void:
	print(body)
	bodiesInsideThruster.erase(body)


