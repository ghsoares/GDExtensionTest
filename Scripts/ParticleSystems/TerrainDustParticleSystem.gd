extends ParticleSystem

var planet
var windSpeed := 0.0
var currentRate := 0.0

export (float) var spread := 16.0
export (float) var hueVariation = .1
export (Vector2) var sizeRange = Vector2(1.0, 2.0)
export (Curve) var sizeCurve
export (Gradient) var gradient

func AddRate(rate: float, override = {}) -> void:
	currentRate += rate
	while currentRate >= 1.0:
		EmitParticle(override)
		currentRate -= 1.0
	pass

func InitParticle(particle, override = {}) -> void:
	.InitParticle(particle, override)
	
	var spr = override.get("spread", spread)
	
	var posX = particle.position.x + rand_range(-spr, spr) / 2.0
	var posY = planet.terrain.GetTerrainY(posX)
	
	particle.size *= rand_range(sizeRange.x, sizeRange.y)
	particle.color.h += rand_range(-1, 1) * hueVariation
	
	particle.position = Vector2(posX, posY)
	particle.velocity *= rand_range(.5, 1.0)

func UpdateParticle(particle, delta: float) -> void:
	.UpdateParticle(particle, delta)
	var lifeT = particle.life / particle.lifetime
	
	particle.velocity += Vector2.RIGHT * delta * windSpeed
	
	if sizeCurve:
		var s = sizeCurve.interpolate(lifeT)
		particle.size = particle.startSize * s
	if gradient:
		var col = gradient.interpolate(lifeT)
		particle.color = particle.startColor * col
