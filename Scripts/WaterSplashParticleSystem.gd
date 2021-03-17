tool
extends ParticleSystem2D

var currentEmitRate = 0.0

export (float) var emissionRate := 1.0
export (float) var coneAngle := 15.0
export (Vector2) var numParticlesRange := Vector2(16, 32)
export (Vector2) var velocityRange := Vector2(32, 64)
export (Vector2) var lifetimeRange := Vector2(1.0, 1.5)
export (Vector2) var sizeRange := Vector2(8.0, 16.0)
export (Curve) var sizeCurve
export (Gradient) var gradient

func _ready() -> void:
	emissionRate = 1.0
	emitting = true

func UpdateSystem(delta: float) -> void:
	.UpdateSystem(delta)
	currentEmitRate += delta * emissionRate
	while currentEmitRate >= 1.0:
		Splash({"position": global_position})
		currentEmitRate -= 1.0

func Splash(override = {}) -> void:
	var numParticles = round(rand_range(numParticlesRange.x, numParticlesRange.y))
	for i in range(numParticles): EmitParticle(override)

func InitParticle(particle, override = {}) -> void:
	if !particle: return
	.InitParticle(particle, override)
	var a = deg2rad(rand_range(-coneAngle, coneAngle))
	var dir := Vector2.UP.rotated(a)
	var speed = rand_range(velocityRange.x, velocityRange.y)
	var size = rand_range(sizeRange.x, sizeRange.y)
	
	particle.velocity = dir * speed
	particle.size = Vector2.ONE * size
	particle.startSize = Vector2.ONE * size

func UpdateParticle(particle, delta: float) -> void:
	.UpdateParticle(particle, delta)
	var lifeT = particle.life / particle.lifetime
	
	if sizeCurve:
		var s = sizeCurve.interpolate(lifeT)
		particle.size = particle.startSize * s
	if gradient:
		var col = gradient.interpolate(lifeT)
		particle.color = particle.startColor * col




