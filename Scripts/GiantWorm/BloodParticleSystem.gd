extends ParticleSystem

export (float) var spread := 15.0
export (Vector2) var sizeRange = Vector2(4.0, 8.0)
export (Vector2) var velocityRange = Vector2(16, 64)
export (Vector2) var lifetimeRange = Vector2(.5, 1.0)
export (Curve) var sizeCurve
export (Gradient) var gradient

func InitParticle(particle: Particle, override = {}) -> void:
	.InitParticle(particle, override)
	
	particle.size *= rand_range(sizeRange.x, sizeRange.y)
	particle.velocity = particle.velocity.normalized() * rand_range(velocityRange.x, velocityRange.y)
	particle.velocity = particle.velocity.rotated(rand_range(-1, 1) * deg2rad(spread / 2.0))
	particle.life = rand_range(lifetimeRange.x, lifetimeRange.y)

func UpdateParticle(particle: Particle, delta: float) -> void:
	.UpdateParticle(particle, delta)
	var lifeT = particle.life / particle.lifetime
	
	if sizeCurve:
		var s = sizeCurve.interpolate(lifeT)
		particle.size = particle.startSize * s
	if gradient:
		var col = gradient.interpolate(lifeT)
		particle.color = particle.startColor * col

