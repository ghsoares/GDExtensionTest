extends ParticleSystem

var currentRate : float = 0.0

export (float) var rate = 64.0
export (float) var circle := 1.0
export (float) var spreadAngle = 0.0
export (Vector2) var speedRange := Vector2(32.0, 64.0)
export (Vector2) var sizeRange := Vector2(1.0, 2.0)
export (Curve) var sizeCurve
export (Gradient) var gradient

func UpdateSystem(delta: float) -> void:
	.UpdateSystem(delta)
	currentRate += delta * rate
	while currentRate >= 1.0:
		EmitParticle()
		currentRate -= 1.0

func InitParticle(particle: Particle, override = {}) -> void:
	.InitParticle(particle, override)
	
	particle.position = Vector2.RIGHT.rotated(randf() * PI * 2.0) * randf() * circle
	particle.velocity = Vector2.DOWN.rotated(
		deg2rad(rand_range(-spreadAngle, spreadAngle)) / 2.0
	)
	particle.velocity *= rand_range(speedRange.x, speedRange.y)
	particle.size = Vector2.ONE * rand_range(sizeRange.x, sizeRange.y)

func UpdateParticle(particle: Particle, delta: float) -> void:
	.UpdateParticle(particle, delta)
	var lifeT = particle.life / particle.lifetime
	
	if sizeCurve:
		var s = sizeCurve.interpolate(lifeT)
		particle.size = particle.startSize * s
	if gradient:
		var col = gradient.interpolate(lifeT)
		particle.color = particle.startColor * col
