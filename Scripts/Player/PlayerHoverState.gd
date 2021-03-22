extends State

export (float) var maxAngularVelocity = 15.0
export (float) var maxVelocity = 128.0
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

func physics_process() -> void:
	thrusterAdd = Input.get_action_strength("thruster_add") - Input.get_action_strength("thruster_subtract")
	angAdd = Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	
	currentThrusterForce += thrusterAdd * thrusterAddSensitivity * fixedDeltaTime
	currentThrusterForce = clamp(currentThrusterForce, 0, maxThrusterForce)
	
	var thrusterT = currentThrusterForce / maxThrusterForce
	
	root.thrusterParticleSystem.rate = thrusterT * 32.0
	root.groundParticleSystem.rate = thrusterT * 32.0
	
	root.linear_velocity += Vector2.RIGHT * root.planet.windSpeed * fixedDeltaTime * .25
	
	root.linear_velocity += -root.global_transform.y * currentThrusterForce * fixedDeltaTime
	root.angular_velocity += angAdd * angularAcceleration * fixedDeltaTime
	
	root.linear_velocity -= root.linear_velocity * clamp(velocityDrag * fixedDeltaTime, 0, 1)
	root.angular_velocity -= root.angular_velocity * clamp(angularVelocityDrag * fixedDeltaTime, 0, 1)
	
	root.angular_velocity = clamp(root.angular_velocity, -maxAngularVelocity, maxAngularVelocity)
	root.linear_velocity = root.linear_velocity.clamped(maxVelocity)
	
	if root.collidedPoints.size() > 0:
		var platformPlacer = root.planet.terrain.platformsPlacer
		var platform :Platform= platformPlacer.GetNearest(root.position.x)
		
		var safeLanding = true
		
		print(root.rotation_degrees, ", ", root.linear_velocity)
		
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
			stateMachine.queryState("Landed")
		else:
			stateMachine.queryState("Dead")

func exit() -> void:
	root.thrusterParticleSystem.rate = 0.0
	root.groundParticleSystem.rate = 0.0





