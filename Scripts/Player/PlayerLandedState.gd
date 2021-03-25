extends State

var platform

export (int) var angleScoreAmount = 250
export (int) var speedScoreAmount = 500
export (int) var distanceScoreAmount = 250
export (int) var scoreRound = 50
export (float) var minPerfectDistance = 4.0
export (float) var fuelAdd = 20.0

func enter() -> void:
	CalculateScore()
	var camera: GameCamera = root.planet.camera
	camera.desiredZoom = root.platformZoomRange.x

func CalculateScore() -> void:
	var perfectScore = (angleScoreAmount + speedScoreAmount + distanceScoreAmount) * platform.scoreMultiplier
	var dist = abs(root.global_position.x - platform.global_position.x)
	
	var angleScore = 1.0 - inverse_lerp(root.minPerfectAngle, root.maxSafeAngle, abs(root.rotation_degrees))
	var speedScore = 1.0 - inverse_lerp(root.minPerfectVelocity, root.maxSafeVelocity, root.linear_velocity.length())
	var distanceScore = 1.0 - inverse_lerp(minPerfectDistance, platform.size / 2.0, dist)
	
	angleScore = clamp(angleScore, 0.0, 1.0) * angleScoreAmount
	speedScore = clamp(speedScore, 0.0, 1.0) * speedScoreAmount
	distanceScore = clamp(distanceScore, 0.0, 1.0) * distanceScoreAmount
	
	var totalScore = (angleScore + speedScore + distanceScore) * platform.scoreMultiplier
	totalScore = int(stepify(totalScore, scoreRound))
	totalScore += int(stepify(abs(root.planet.windSpeed) * 5, 5))
	if root.insideWater:
		totalScore += 250
	
	var perfect = totalScore >= perfectScore
	
	var perc = totalScore / float(perfectScore)
	var addFuel = int(perc * fuelAdd * platform.scoreMultiplier)
	PlayerStats.currentFuel += addFuel

func physics_process() -> void:
	if Input.is_action_just_pressed("next_level"):
		stateMachine.queryState("TakeOff")






