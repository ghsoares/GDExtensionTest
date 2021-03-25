extends ParticleSystem

var currentRate = 0.0

export (Vector2) var amountRange = Vector2(32, 64)
export (Vector2) var velocityRange = Vector2(128, 256)
export (Vector2) var sizeRange = Vector2(4.0, 8.0)
export (Vector2) var lifetimeRange = Vector2(.5, 1.0)
export (float) var drag = 2.0
export (Curve) var processCurve
export (Curve) var dragCurve

export (Curve) var sizeCurve
export (Gradient) var gradient

func Explosion() -> void:
	var amnt = int(rand_range(amountRange.x, amountRange.y + 1))
	for i in range(amnt):
		EmitParticle()

func InitParticle(particle: Particle, override = {}) -> void:
	.InitParticle(particle, override)
	var vel = Vector2.UP.rotated(rand_range(-1, 1) * PI * .5)
	vel *= rand_range(velocityRange.x, velocityRange.y)
	particle.velocity = vel
	particle.size = Vector2.ONE * rand_range(sizeRange.x, sizeRange.y)
	particle.life = rand_range(lifetimeRange.x, lifetimeRange.y)

func UpdateParticle(particle: Particle, delta: float) -> void:
	var lifeT = particle.life / particle.lifetime
	if processCurve:
		delta *= processCurve.interpolate(lifeT)
	.UpdateParticle(particle, delta)
	lifeT = particle.life / particle.lifetime
	
	var pDrag = drag
	if dragCurve:
		pDrag *= dragCurve.interpolate(lifeT)
	
	particle.velocity -= particle.velocity * clamp(delta * pDrag, 0.0, 1.0)
	
	if sizeCurve:
		var s = sizeCurve.interpolate(lifeT)
		particle.size = particle.startSize * s
	if gradient:
		var col = gradient.interpolate(lifeT)
		particle.color = particle.startColor * col
