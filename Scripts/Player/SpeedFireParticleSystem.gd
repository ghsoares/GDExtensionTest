extends ParticleSystem

var currentRate := 0.0

export (float) var maxSafeSpeed := 16.0
export (float) var maxSpeed := 64.0
export (float) var maxRate := 32.0
export (float) var radius := 8.0
export (float) var spreadAngle := 5.0
export (float) var velocityMultiply := .1
export (float) var maxParticleVelocity = 32.0
export (Vector2) var sizeRange := Vector2(.5, 1.0)
export (Vector2) var lifetimeRange := Vector2(.25, .5)
export (Curve) var sizeCurve
export (Gradient) var gradient

func UpdateSystem(delta: float) -> void:
	.UpdateSystem(delta)
	global_rotation = 0.0
	var rate = currentVelocity.length()
	rate = clamp(inverse_lerp(maxSafeSpeed, maxSpeed, rate), 0.0, 1.0)
	rate *= maxRate
	currentRate += rate * delta
	while currentRate >= 1.0:
		EmitParticle()
		currentRate -= 1.0

func InitParticle(particle: Particle, override = {}) -> void:
	.InitParticle(particle, override)
	var dir :Vector2= currentVelocity.normalized()
	dir = dir.rotated(deg2rad(rand_range(-spreadAngle, spreadAngle)))
	
	var pos := dir * radius
	var vel := -currentVelocity * velocityMultiply
	vel = vel.clamped(maxParticleVelocity)
	
	particle.position = pos
	particle.velocity = vel
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

