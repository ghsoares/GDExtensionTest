extends State

class_name PlayerLandedState

var platform
var queryNext = false
var canContinue = false
var continuing = false

export (int) var angleScoreAmount = 250
export (int) var speedScoreAmount = 500
export (int) var distanceScoreAmount = 250
export (int) var scoreRound = 50
export (float) var minPerfectDistance = 4.0
export (float) var fuelAdd = 20.0
export (Gradient) var scoreFuelGradient

func enter() -> void:
	queryNext = false
	canContinue = false
	continuing = false
	calculate_score()

func calculate_score() -> void:
	var perfectScore = (angleScoreAmount + speedScoreAmount + distanceScoreAmount) * platform.scoreMultiplier
	var dist = abs(root.global_position.x - platform.global_position.x)
	
	var angleScore = 1.0 - inverse_lerp(root.minPerfectAngle, root.maxSafeAngle, root.rotation_degrees)
	var speedScore = 1.0 - inverse_lerp(root.minPerfectSpeed, root.maxSafeSpeed, root.linear_velocity.length())
	var distanceScore = 1.0 - inverse_lerp(minPerfectDistance, platform.size / 2.0, dist)
	
	angleScore = clamp(angleScore, 0.0, 1.0) * angleScoreAmount
	speedScore = clamp(speedScore, 0.0, 1.0) * speedScoreAmount
	distanceScore = clamp(distanceScore, 0.0, 1.0) * distanceScoreAmount
	
	var totalScore = (angleScore + speedScore + distanceScore) * platform.scoreMultiplier
	totalScore += abs(root.windSpeed) * 50
	totalScore = int(stepify(totalScore, scoreRound))
	
	var perfect = totalScore >= perfectScore
	
	if perfect:
		PlayerStats.perfects += 1
		PlayerStats.perfectsStreak += 1
		totalScore += PlayerStats.perfectsStreak * 250
	else:
		PlayerStats.PerfectsStreakBreak()
	
	var perc = totalScore / float(perfectScore)
	var addFuel = int(perc * fuelAdd) * platform.scoreMultiplier
	PlayerStats.fuel += addFuel
	
	if perfect:
		var text = "Perfect"
		if PlayerStats.perfectsStreak > 1:
			text += " x" + str(PlayerStats.perfectsStreak)
		root.scoreParticlesParticleSystem.EmitParticle({
			"text": text + "!",
		})
		yield(get_tree().create_timer(.25), "timeout")
	
	PlayerStats.totalScore += totalScore
	PlayerStats.fuel += addFuel
	
	root.scoreParticlesParticleSystem.EmitParticle({
		"text": "+" + str(totalScore)
	})
	yield(get_tree().create_timer(.25), "timeout")
	
	root.scoreParticlesParticleSystem.EmitParticle({
		"text": "+" + str(addFuel) + " Fuel",
		"gradient": scoreFuelGradient
	})
	
	canContinue = true

func process() -> void:
	#queryNext = 
	pass

func physics_process() -> void:
	root.linear_velocity += Vector2.DOWN * root.world.settings.gravityScale * fixedDeltaTime
	if Input.is_action_just_pressed("next_level") and canContinue and !continuing:
		Transition.Animate()
		continuing = true
	if continuing and !Transition.animating:
		root.world.Generate()








