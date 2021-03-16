tool
extends ParticleSystem2D

var currentEmitRate = 0.0

export (float) var rate := 1.0
export (Vector2) var numParticlesRange := Vector2(16, 32)
export (Vector2) var velocityRange := Vector2(32, 64)
export (Vector2) var lifetimeRange = Vector2(1.0, 1.5)
export (Curve) var sizeCurve
export (Gradient) var gradient
export (Curve) var dragCurve

func _ready() -> void:
	if !Engine.editor_hint:
		rate = 0.0
		emitting = true

func UpdateSystem(delta: float) -> void:
	.UpdateSystem(delta)
	currentEmitRate += delta * rate
	while currentEmitRate >= 1.0:
		currentEmitRate -= 1.0
		Explode()

func Explode():
	var numParticles = round(rand_range(numParticlesRange.x, numParticlesRange.y))
	for i in range(numParticles): EmitParticle()

func InitParticle(particle: Particle, override: Dictionary = {}) -> void:
	if !particle: return
	.InitParticle(particle, override)
	var a = randf() * PI * 2.0
	var life = rand_range(lifetimeRange.x, lifetimeRange.y)
	
	var dir := Vector2.RIGHT.rotated(a)
	var speed = rand_range(velocityRange.x, velocityRange.y)
	particle.velocity = dir * speed
	particle.life = life
	particle.lifetime = life

func UpdateParticle(particle: Particle, delta: float) -> void:
	.UpdateParticle(particle, delta)
	var lifeT = particle.life / particle.lifetime
	
	if sizeCurve:
		var s = sizeCurve.interpolate(lifeT)
		particle.size = Vector2.ONE * s
	if gradient:
		var col = gradient.interpolate(lifeT)
		particle.color = col
	if dragCurve:
		var drag = dragCurve.interpolate(lifeT)
		particle.velocity -= particle.velocity * clamp(delta * drag, 0.0, 1.0)




