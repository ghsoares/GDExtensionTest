tool
extends ParticleSystem2D

var currentEmitRate = 0.0

export (float) var emitRate = 32.0
export (Vector2) var velocityRange = Vector2(32.0, 64.0)
export (Vector2) var lifetimeRange = Vector2(1.0, 1.5)
export (Curve) var sizeCurve
export (Gradient) var gradient

func UpdateSystem(delta: float) -> void:
	.UpdateSystem(delta)
	currentEmitRate += emitRate * delta
	while currentEmitRate >= 1.0:
		currentEmitRate -= 1.0
		EmitParticle()

func InitParticle(particle, override: Dictionary = {}) -> void:
	if !particle: return
	.InitParticle(particle, override)
	var a = randf() * PI * 2.0
	var life = rand_range(lifetimeRange.x, lifetimeRange.y)
	
	var dir := Vector2.RIGHT.rotated(a)
	var speed = rand_range(velocityRange.x, velocityRange.y)
	particle.velocity = dir * speed
	particle.life = life
	particle.lifetime = life

func UpdateParticle(particle, delta: float) -> void:
	.UpdateParticle(particle, delta)
	var lifeT = particle.life / particle.lifetime
	
	if sizeCurve:
		var s = sizeCurve.interpolate(lifeT)
		particle.size = particle.startSize * s
	if gradient:
		var col = gradient.interpolate(lifeT)
		particle.color = col






