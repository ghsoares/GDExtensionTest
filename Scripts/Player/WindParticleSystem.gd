extends ParticleSystem

var currentRate := 0.0

export (float) var ratePerWindSpeed = .1
export (float) var windSpeed = 0.0
export (float) var maxRate = 32.0
export (float) var mass = .25
export (int) var numPoints = 8
export (float) var waveFrequency = 2.0
export (float) var waveMagnitude = 2.0
export (Vector2) var rectSize = Vector2(16.0, 16.0)
export (Vector2) var sizeRange = Vector2(2.0, 4.0)
export (Curve) var sizeCurve
export (float) var speed = 32.0

func UpdateSystem(delta: float) -> void:
	.UpdateSystem(delta)
	global_rotation = 0.0
	
	var r = 0.0
	if windSpeed > 0.0:
		r = windSpeed - currentVelocity.x
	else:
		r = abs(windSpeed) + currentVelocity.x
	r = max(r, 0.0)
	
	currentRate += clamp(r * ratePerWindSpeed * delta, 0.0, maxRate)
	while currentRate >= 1.0:
		EmitParticle()
		currentRate -= 1.0

func InitParticle(particle: Particle, override = {}) -> void:
	.InitParticle(particle, override)
	var pos = Vector2(
		rand_range(-rectSize.x, rectSize.x) / 2.0,
		rand_range(-rectSize.y, rectSize.y) / 2.0
	)
	particle.position = pos
	particle.size = Vector2.ONE * rand_range(sizeRange.x, sizeRange.y)
	particle.velocity = Vector2.RIGHT * sign(windSpeed) * speed
	
	var points = []
	for i in range(numPoints):
		points.append(particle.GetTransform())
	particle.customData["Trail"] = points

func UpdateParticle(particle: Particle, delta: float) -> void:
	.UpdateParticle(particle, delta)
	var lifeT = particle.life / particle.lifetime
	
	particle.position += Vector2.UP * sin((particle.life + particle.idx * .1) * PI * 2.0 * waveFrequency) * waveMagnitude * waveFrequency * delta

	if sizeCurve:
		var s = sizeCurve.interpolate(lifeT)
		particle.size = particle.startSize * s
	
	SnakeTrail(particle)

func SnakeTrail(particle: Particle) -> void:
	var trail :Array= particle.customData["Trail"]
	if trail.size() == 0:
		return
	
	var i = trail.size() - 1
	while i >= 0:
		var curr :Transform2D = trail[i]
		if i == 0:
			curr = particle.GetTransform()
		else:
			var next :Transform2D= trail[i-1]
			curr = next
		
		trail[i] = curr
		
		i -= 1

func DrawParticles() -> void:
	.DrawParticles()
	for particle in particles:
		if particle.alive:
			var trail :Array= particle.customData["Trail"]
			DrawPolyline(trail, particle.color)














