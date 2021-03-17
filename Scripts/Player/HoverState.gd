extends State

class_name PlayerHoverState

export (float) var maxAngularVelocity = 15.0
export (float) var maxThrusterForce = 320.0
export (float) var thrusterAddSensitivity = 10.0
export (float) var angularAcceleration = 15.0
export (float) var velocityDrag = 8.0
export (float) var angularVelocityDrag = 8.0

var currentThrusterForce = 0.0
var thrusterAdd = 0.0
var angAdd = 0.0

func enter() -> void:
	currentThrusterForce = 0.0
	root.rocketParticleSystem.emitting = true
	root.windParticleSystem.emitting = true

func process() -> void:
	thrusterAdd = Input.get_action_strength("thruster_add") - Input.get_action_strength("thruster_subtract")
	angAdd = Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	if Input.is_action_pressed("slowmo"):
		Engine.time_scale = lerp(Engine.time_scale, .25, min(deltaTime * 8.0, 1.0))
	else:
		Engine.time_scale = lerp(Engine.time_scale, 1.0, min(deltaTime * 8.0, 1.0))

func physics_process() -> void:
	var forceMultiply = 1.0
	if root.insideWater:
		thrusterAdd *= .25
		angAdd *= .25
	
	if PlayerStats.fuel <= 0.0:
		thrusterAdd = 0.0
		currentThrusterForce = 0.0
	
	currentThrusterForce += thrusterAdd * thrusterAddSensitivity * fixedDeltaTime
	
	currentThrusterForce = clamp(currentThrusterForce, 0, maxThrusterForce)
	
	var thrusterPerc = currentThrusterForce / maxThrusterForce
	root.rocketParticleSystem.emitRate = 64.0 * thrusterPerc
	root.windParticleSystem.windSpeed = Vector2.RIGHT * root.world.settings.currentWindSpeed
	
	root.linear_velocity += Vector2.DOWN * root.world.settings.gravityScale * fixedDeltaTime
	root.linear_velocity += Vector2.RIGHT * root.world.settings.currentWindSpeed * fixedDeltaTime
	
	root.linear_velocity += -root.global_transform.y * currentThrusterForce * forceMultiply * fixedDeltaTime
	root.angular_velocity += angAdd * angularAcceleration * fixedDeltaTime
	
	root.linear_velocity -= root.linear_velocity * clamp(velocityDrag * fixedDeltaTime, 0, 1)
	root.angular_velocity -= root.angular_velocity * clamp(angularVelocityDrag * fixedDeltaTime, 0, 1)
	
	root.angular_velocity = clamp(root.angular_velocity, -maxAngularVelocity, maxAngularVelocity)
	
	PlayerStats.fuel -= currentThrusterForce * PlayerStats.fuelLoseRate * fixedDeltaTime
	
	if root.collidedPoints.size() > 0:
		if !root.SafeLanding():
			queryState("Dead")
			return
		
		var nearestPlatform = root.world.platformPlacer.GetNearestPlatform(root.global_position.x)
		var safeLanding = true
		
		for colP in root.collisionPoints:
			var worldP = root.to_global(colP)
			var dist = nearestPlatform.DistX(worldP.x)
			if dist > 0.0:
				safeLanding = false
		
		if !safeLanding:
			queryState("Dead")
			return
		
		var state = queryState("Landed")
		state.platform = nearestPlatform

func exit() -> void:
	Engine.time_scale = 1.0
	root.rocketParticleSystem.emitting = false
	root.windParticleSystem.emitting = false




