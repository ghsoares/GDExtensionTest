extends ParticleSystem


export (float) var spreadAngle = 0.0
export (Vector2) var amountRange = Vector2(32, 64)
export (Vector2) var speedRange := Vector2(32.0, 64.0)
export (Vector2) var sizeRange := Vector2(1.0, 2.0)
export (Vector2) var lifetimeRange := Vector2(.25, .5)
export (Curve) var sizeCurve
export (Gradient) var gradient

func Explode() -> void:
	var amnt = int(rand_range(amountRange.x, amountRange.y + 1))
	for i in range(amnt):
		EmitParticle()

func InitParticle(particle: Particle, override = {}) -> void:
	.InitParticle(particle, override)
	
	var dir = Vector2.DOWN.rotated(deg2rad(rand_range(-spreadAngle, spreadAngle)))
	particle.velocity = dir * rand_range(speedRange.x, speedRange.y)
	
	particle.size = Vector2.ONE * rand_range(sizeRange.x, sizeRange.y)
	
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
