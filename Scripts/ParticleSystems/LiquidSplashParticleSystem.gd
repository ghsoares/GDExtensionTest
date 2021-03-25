extends ParticleSystem

export (float) var spread = 2.0
export (Vector2) var sizeRange = Vector2(1.0, 2.0)
export (Curve) var sizeCurve

func InitParticle(particle, override = {}) -> void:
	.InitParticle(particle, override)
	particle.position += Vector2.RIGHT.rotated(randf() * PI * 2.0) * randf() * spread
	particle.size = Vector2.ONE * rand_range(sizeRange.x, sizeRange.y)

func UpdateParticle(particle, delta: float) -> void:
	.UpdateParticle(particle, delta)
	var lifeT = particle.life / particle.lifetime
	
	if sizeCurve:
		var s = sizeCurve.interpolate(lifeT)
		particle.size = particle.startSize * s
