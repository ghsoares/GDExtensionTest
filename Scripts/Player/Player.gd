extends RigidBody2D

class_name Player

var startTransform

var world
var collisionPoints = []
var collidedPoints = []
var insideWater = null

export (float) var minPerfectSpeed = 4.0
export (float) var minPerfectAngle = 1.0
export (float) var maxSafeSpeed = 32.0
export (float) var maxSafeAngle = 5.0
export (float) var shipFriction = 4.0
export (float) var maxVelocity = 200.0

export (Gradient) var debugScoreGradient

const COLLISION_SAMPLE_RESOLUTION = 2

onready var stateMachine = $StateMachine
onready var spr : Sprite = $Sprite
onready var scoreSpr : Sprite = $Sprite/ScoreColor
onready var colShape : CollisionShape2D = $Col
onready var rectShape : RectangleShape2D = $Col.shape

onready var rocketParticleSystem = $ParticleSystems/Rocket
onready var explosionParticleSystem = $ParticleSystems/Explosion
onready var explosionParticlesParticleSystem = $ParticleSystems/ExplosionParticles
onready var scoreParticlesParticleSystem = $ParticleSystems/ScoreParticles
onready var windParticleSystem = $ParticleSystems/Wind

onready var speedPivot = $Speed
onready var speedMaterial = $Speed/Speed.material

func SampleCheckPoints() -> void:
	collisionPoints = []
	
	var p0 = rectShape.extents * Vector2(-1, 1)
	var p1 = rectShape.extents * Vector2(-1, -1)
	
	for i in range(4):
		for j in range(0, COLLISION_SAMPLE_RESOLUTION - 1):
			var t = j / float(COLLISION_SAMPLE_RESOLUTION - 1)
			collisionPoints.append(p0.linear_interpolate(p1, t))
		p0 = p1
		p1 = (p1 - Vector2.ONE * .5).rotated(PI * .5) + Vector2.ONE * .5

func CreateSpeedGradient() -> void:
	var grad = Gradient.new()
	var offsets = []
	var colors = [
		Color(0.243137, 0.572549, 1),
		Color(0.203922, 1, 0.576471),
		Color(1, 0.827451, 0),
		Color(1, 0, 0),
		Color(0.490196, 0, 0.239216)
	]
	
	var middleSpeed = (minPerfectSpeed + maxSafeSpeed) / 2.0
	var margin = 4.0
	
	offsets.append(minPerfectSpeed / maxSafeSpeed)
	offsets.append(minPerfectSpeed / maxSafeSpeed)
	offsets.append(middleSpeed / maxSafeSpeed)
	offsets.append((maxSafeSpeed - margin) / maxSafeSpeed)
	offsets.append(1.0)
	
	grad.offsets = offsets
	grad.colors = colors
	var gradTex = GradientTexture.new()
	gradTex.gradient = grad
	
	speedMaterial.set_shader_param("progressGradient", gradTex)

func _ready() -> void:
	startTransform = global_transform
	SampleCheckPoints()
	CreateSpeedGradient()
	stateMachine.root = self
	stateMachine.start()
	world.camera.Warp(global_position)
	
	rocketParticleSystem.world = world
	explosionParticlesParticleSystem.world = world

func _physics_process(delta: float) -> void:
	if insideWater:
		linear_velocity -= linear_velocity * clamp(insideWater.drag * delta, 0, 1)
	
	world.camera.desiredPosition = global_position
	TerrainCollision(delta)
	stateMachine.physics_process(delta)
	
	linear_velocity = linear_velocity.clamped(maxVelocity)
	
	PlayerStats.fuel = clamp(PlayerStats.fuel, 0.0, PlayerStats.maxFuel)

func _process(delta: float) -> void:
	var speedScore = 1.0 - inverse_lerp(minPerfectSpeed, maxSafeSpeed, linear_velocity.length())
	var angleScore = 1.0 - inverse_lerp(minPerfectAngle, maxSafeAngle, abs(rotation_degrees))
	speedScore = clamp(speedScore, 0, 1)
	angleScore = clamp(angleScore, 0, 1)
	var totalScore = (speedScore + angleScore) / 2.0
	
	totalScore = floor(totalScore * 8.0) / 8.0
	
	var col = debugScoreGradient.interpolate(totalScore)
	col.a = scoreSpr.modulate.a
	scoreSpr.modulate = col
	
	stateMachine.process(delta)
	update()
	
	var speed = linear_velocity.length()
	var speedProgress = speed / maxSafeSpeed
	
	if speed >= maxSafeSpeed:
		speedMaterial.set_shader_param("pulseMagnitude", 1)
	else:
		speedMaterial.set_shader_param("pulseMagnitude", .0)
	
	speedMaterial.set_shader_param("progress", speedProgress)
	speedPivot.global_rotation = 0.0

func TerrainCollision(var delta) -> void:
	collidedPoints = []
	var differences = []
	
	var terrain = world.terrain
	var extents = rectShape.extents
	var numCollisionPoints = collisionPoints.size()
	
	for p in collisionPoints:
		var worldP = to_global(p)
		
		var h = terrain.SampleCollisionHeight(worldP.x)
		var hY = terrain.size.y - h
		
		var diff = worldP.y - hY
		
		if diff >= 0.0:
			var normal = terrain.SampleNormal(worldP.x)
			var colDot = 1.0 - (linear_velocity.normalized().dot(normal) * .5 + .5)
			collidedPoints.append(p)

func SafeLanding() -> bool:
	return linear_velocity.length() <= maxSafeSpeed and abs(rotation_degrees) <= maxSafeAngle

func GetCurrentState():
	return stateMachine.currState

func _draw() -> void:
#	for p in collisionPoints:
#		var c = Color.green
#		if p in collidedPoints:
#			c = Color.red
#		draw_circle(p, 2.0, c)
#		draw_line(Vector2.ZERO, global_transform.basis_xform_inv(linear_velocity), Color.white, 2.0)
	pass

