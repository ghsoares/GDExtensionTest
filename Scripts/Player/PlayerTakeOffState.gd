extends State

var prevPos: Vector2
var startPos: Vector2
var finalPos: Vector2
var rate = 0.0
var currTransitionTime = 0.0
var transiting := false

export (float) var maxThrusterRate = 64.0
export (float) var acceleration = 64.0
export (float) var transitionTime = 2.0
export (float, EASE) var transitionCurve := 1.0

func enter() -> void:
	prevPos = startPos
	startPos = root.global_position
	finalPos = Vector2(startPos.x, -128.0)
	rate = 0.0
	currTransitionTime = 0.0
	transiting = false
	root.mode = RigidBody2D.MODE_KINEMATIC

func physics_process() -> void:
	var camera: GameCamera = root.planet.camera
	
	rate += acceleration * fixedDeltaTime
	rate = min(rate, maxThrusterRate)
	
	root.rotation_degrees = lerp(root.rotation_degrees, 0.0, clamp(fixedDeltaTime * 2.0, 0.0, 1.0))
	
	if root.insideWater and PlayerStats.hasWaterThruster:
		root.thrusterParticleSystem.rate = 0.0
		root.groundParticleSystem.rate = 0.0
		root.waterThrusterParticleSystem.rate = rate
		root.waterGroundParticleSystem.rate = rate
	else:
		root.thrusterParticleSystem.rate = rate
		root.groundParticleSystem.rate = rate
		root.waterThrusterParticleSystem.rate = 0.0
		root.waterGroundParticleSystem.rate = 0.0
	
	var platformPlacer = root.planet.terrain.platformsPlacer
	var platform :Platform= platformPlacer.GetNearest(root.position.x)
	
	if rate >= maxThrusterRate:
		camera.desiredZoom = root.GetPlatformZoom()
		
		currTransitionTime += fixedDeltaTime
		var t = currTransitionTime / transitionTime
		t = ease(t, transitionCurve)
		t = clamp(t, 0.0, 1.0)
		root.global_position = startPos.linear_interpolate(finalPos, t)
		
		if t >= 1.0:
			Transition()
	
	root.linear_velocity = (root.global_position - prevPos) / fixedDeltaTime
	
	prevPos = root.global_position

func Transition() -> void:
	if transiting: return
	transiting = true
	Transition.FadeIn()
	yield(Transition, "FadeFinished")
	root.planet.Generate()

func exit() -> void:
	root.mode = RigidBody2D.MODE_RIGID
	pass

