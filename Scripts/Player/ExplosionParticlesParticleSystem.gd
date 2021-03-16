tool
extends ParticleSystem2D

var world

var currentEmitRate = 0.0

export (float) var rate := 1.0
export (float) var emissionRate := 1.0
export (float) var coneAngle := 15.0
export (Vector2) var numParticlesRange := Vector2(16, 32)
export (Vector2) var velocityRange := Vector2(32, 64)
export (Curve) var sizeCurve
export (float) var bounciness := .5

onready var subEmitter = $FireParticles

func _ready() -> void:
	if !Engine.editor_hint:
		emissionRate = 0.0
		emitting = true

func UpdateSystem(delta: float) -> void:
	.UpdateSystem(delta)
	if !subEmitter:
		subEmitter = $FireParticles
	currentEmitRate += delta * emissionRate
	while currentEmitRate >= 1.0:
		Explode()
		currentEmitRate -= 1.0

func Explode():
	var numParticles = round(rand_range(numParticlesRange.x, numParticlesRange.y))
	for i in range(numParticles): EmitParticle()

func InitParticle(particle, override = {}) -> void:
	if !particle: return
	.InitParticle(particle, override)
	var a = deg2rad(rand_range(-coneAngle, coneAngle))
	var dir := Vector2.UP.rotated(a)
	var speed = rand_range(velocityRange.x, velocityRange.y)
	
	particle.customData["prevTrailPosition"] = particle.position
	particle.velocity = dir * speed

func UpdateParticle(particle: Particle, delta: float) -> void:
	if !particle: return
	.UpdateParticle(particle, delta)
	var lifeT = particle.life / particle.lifetime
	
	if world:
		var terrainY = world.terrain.size.y - world.terrain.SampleCollisionHeight(particle.position.x)
		var off = particle.position.y - terrainY
		if off > 0.0:
			var normal = world.terrain.SampleNormal(particle.position.x)
			var velocitySlide = particle.velocity.slide(normal)
			var velocityBounce = particle.velocity.bounce(normal)
			particle.position.y -= off
			particle.velocity = velocitySlide.linear_interpolate(velocityBounce, bounciness)
	
	if sizeCurve:
		var s = sizeCurve.interpolate(lifeT)
		particle.size = Vector2.ONE * s
	
	if !particle.customData.has("prevTrailPosition"): return
	
	var prevPos = particle.customData["prevTrailPosition"];
	var curr = particle.position;
	var deltaPos = curr - prevPos;
	var dist = deltaPos.length();
	var deltaS = 1.0 / rate;
	
	if dist >= deltaS:
		var s = 0.0
		while s < dist:
			var t = s / dist
			var pos = prevPos.linear_interpolate(curr, t)
			
			subEmitter.EmitParticle({
				"position": pos,
				"size": particle.size
			}, true)
			
			s += deltaS
		particle.customData["prevTrailPosition"] = curr








