tool
extends ParticleSystem2D

var currentEmitRate := 0.0

export (float) var rate := 1.0
export (Vector2) var rectSize := Vector2(960, 540)
export (Vector2) var sizeRange := Vector2(1.0, 1.5)
export (Curve) var sizeCurve
export (Gradient) var gradient

func UpdateSystem(delta: float) -> void:
	.UpdateSystem(delta)
	currentEmitRate += delta * rate
	while currentEmitRate >= 1.0:
		currentEmitRate -= 1.0
		EmitParticle()

func InitParticle(particle, override = {}) -> void:
	.InitParticle(particle, override)
	var pos = Vector2(randf(), randf()) * rectSize
	particle.position = pos
	particle.size = Vector2.ONE * rand_range(sizeRange.x, sizeRange.y)
	particle.rotation = PI / 4.0

func UpdateParticle(particle, delta: float) -> void:
	if particle == null: return
	.UpdateParticle(particle, delta)
	var lifeT = particle.life / particle.lifetime
	
	if sizeCurve:
		var s = sizeCurve.interpolate(lifeT)
		particle.size = particle.startSize * s
	if gradient:
		var col = gradient.interpolate(lifeT)
		particle.color = particle.startColor * col
