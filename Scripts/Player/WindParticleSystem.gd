tool
extends ParticleSystem2D

var currentRate = 0.0

export (Vector2) var windSpeed := Vector2(32.0, 0.0)
export (Vector2) var rectSize := Vector2(16.0, 8.0)
export (Vector2) var sizeRange := Vector2(.5, 1.0)
export (int) var maxPoints = 12
export (float) var ratePerWindSpeed = 16.0
export (float) var waveFrequency = 2.0
export (float) var waveMagnitude = .1
export (float) var mass = .1
export (Gradient) var gradient

func UpdateSystem(delta: float) -> void:
	.UpdateSystem(delta)
	var windSpeedLen = windSpeed.length()
	currentRate += (windSpeedLen / ratePerWindSpeed) * delta
	while currentRate >= 1.0:
		currentRate -= 1.0
		EmitParticle()

func InitParticle(particle, override = {}) -> void:
	.InitParticle(particle, override)
	var pos = Vector2(
		rand_range(-rectSize.x, rectSize.x) / 2.0,
		rand_range(-rectSize.y, rectSize.y) / 2.0
	).rotated(global_rotation)
	pos += global_position
	
	particle.position = pos
	
	var trail = []
	var transf = particle.GetTransform()
	for i in range(maxPoints):
		trail.append(transf)
	
	particle.customData["trail"] = trail
	particle.size = Vector2.ONE * rand_range(sizeRange.x, sizeRange.y)

func UpdateParticle(particle, delta) -> void:
	.UpdateParticle(particle, delta)
	var lifeT = particle.life / particle.lifetime
	
	particle.velocity += (windSpeed / mass) * delta
	var trail = particle.customData["trail"]
	
	particle.position += windSpeed.rotated(PI / 2.0) * sin((particle.life + particle.idx * .1) * deg2rad(360.0) * waveFrequency) * waveMagnitude * waveFrequency * delta
	
	var idx = trail.size() - 1
	while idx > 0:
		var nxt = trail[idx - 1]
		trail[idx] = nxt
		idx -= 1
	trail[0] = particle.GetTransform()
	
	if gradient:
		var col = gradient.interpolate(lifeT)
		particle.color = col

func DrawParticles() -> void:
	.DrawParticles()
	for particle in particles:
		if particle.alive:
			var trail = particle.customData["trail"]
			if trail.size() >= 2:
				DrawPolyline(trail, particle.color)






