tool
extends ParticleSystem2D

var world
var currentEmitRate = 0.0

export (float) var emitRate = 32.0
export (float) var angle = 15.0
export (Vector2) var velocityRange = Vector2(32.0, 64.0)
export (Vector2) var lifetimeRange = Vector2(1.0, 1.5)
export (float) var velocityInheritScale = .5
export (float) var bounciness = .5
export (Curve) var sizeCurve
export (Gradient) var gradient
export (int) var skipParticlesHeightmap = 4

func UpdateSystem(delta: float) -> void:
	.UpdateSystem(delta)
	currentEmitRate += emitRate * delta
	while currentEmitRate >= 1.0:
		currentEmitRate -= 1.0
		EmitParticle()

func InitParticle(particle: Particle, override: Dictionary = {}) -> void:
	if !particle: return
	.InitParticle(particle)
	var dir = global_transform.y
	var angleRad = deg2rad(angle)
	var life = rand_range(lifetimeRange.x, lifetimeRange.y)
	
	dir = dir.rotated(rand_range(-angleRad, angleRad))
	particle.velocity = dir * rand_range(velocityRange.x, velocityRange.y) + currentVelocity * velocityInheritScale
	particle.life = life
	particle.lifetime = life
	
	particle.size = Vector2.ONE * sizeCurve.interpolate(0.0)

func UpdateParticle(particle: Particle, delta: float) -> void:
	.UpdateParticle(particle, delta)
	var lifeT = particle.life / particle.lifetime
	
	if world:
		var terrainY = world.terrain.size.y - world.terrain.SampleCollisionHeight(particle.position.x)
		var off = particle.position.y - terrainY
		if off > 0.0:
			var normal = world.terrain.SampleNormal(particle.position.x)
			var velocitySlide = particle.velocity.slide(normal)
			var velocityBounce = particle.velocity.bounce(normal)
			particle.position.y -= off
			particle.velocity = velocitySlide.linear_interpolate(velocityBounce, bounciness)
	
	if sizeCurve:
		var s = sizeCurve.interpolate(lifeT)
		particle.size = Vector2.ONE * s
	if gradient:
		var col = gradient.interpolate(lifeT)
		particle.color = col













