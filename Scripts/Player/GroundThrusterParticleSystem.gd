extends ParticleSystem

var planet

var currentRate : float = 0.0

export (float) var rate = 64.0
export (float) var maxDistance = 64.0
export (float) var spread = 16.0
export (Vector2) var sizeRange = Vector2(4.0, 8.0)
export (Vector2) var velocityRange = Vector2(16, 64)
export (Curve) var sizeCurve
export (Gradient) var gradient

func UpdateSystem(delta: float) -> void:
	.UpdateSystem(delta)
	var terrain: Terrain = planet.terrain
	var cast = terrain.RayIntersect(global_position, global_transform.y, maxDistance)
	
	if cast:
		var dist = cast.distance
		currentRate += rate * delta * clamp(1.0 - dist / maxDistance, 0.0, 1.0)
		while currentRate >= 1.0:
			EmitParticle({"cast": cast})
			currentRate -= 1.0

func InitParticle(particle, override = {}) -> void:
	.InitParticle(particle, override)
	var terrain: Terrain = planet.terrain
	var cast = override.get("cast", {})
	
	var off = cast.point + Vector2.RIGHT * rand_range(-spread, spread)
	var terrainY = terrain.GetTerrainY(off.x)
	var velocity :Vector2= (off - global_position).normalized() * rand_range(velocityRange.x, velocityRange.y)
	velocity = velocity.bounce(cast.normal)
	
	off.y = terrainY
	particle.position = off
	particle.velocity = velocity
	particle.size = Vector2.ONE * rand_range(sizeRange.x, sizeRange.y)

func UpdateParticle(particle, delta: float) -> void:
	.UpdateParticle(particle, delta)
	var lifeT = particle.life / particle.lifetime
	
	if sizeCurve:
		var s = sizeCurve.interpolate(lifeT)
		particle.size = particle.startSize * s
	if gradient:
		var col = gradient.interpolate(lifeT)
		particle.color = particle.startColor * col




