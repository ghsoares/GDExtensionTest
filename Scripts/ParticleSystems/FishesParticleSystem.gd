extends ParticleSystem

var planet
var viewportRect: Rect2
var canvasTransform: Transform2D
var globalCanvasTransform: Transform2D

export (Vector2) var rectSize := Vector2(1024, 768)
export (float) var fishSize = 22.0
export (float) var avoidCollisionLength = 32.0
export (float) var avoidCollisionForce = 16.0
export (float) var movementMaxVelocity = 64.0
export (OpenSimplexNoise) var movementNoise: OpenSimplexNoise
export (float) var movementMagnitude = 32.0

func UpdateSystem(delta: float) -> void:
	.UpdateSystem(delta)
	viewportRect = get_viewport_rect()
	canvasTransform = get_canvas_transform()
	globalCanvasTransform = canvasTransform.inverse()

func ResetParticles() -> void:
	.ResetParticles()
	viewportRect = get_viewport_rect()
	for i in range(numParticles):
		EmitParticle()

func InitParticle(particle: Particle, override = {}) -> void:
	.InitParticle(particle, override)
	particle.persistent = true
	particle.size = Vector2.ONE * fishSize
	
	particle.position = global_position + Vector2(randf(), randf()) * rectSize

func UpdateParticle(particle: Particle, delta: float) -> void:
	.UpdateParticle(particle, delta)
	OffsetOffscreen(particle)
	
	var terrain: Terrain = planet.terrain
	var player = planet.player
	var terrainY = terrain.GetTerrainY(particle.position.x)
	var playerOff = (particle.position - player.global_position)
	var playerDir = playerOff.normalized()
	var playerForceT = max(1.0 - playerOff.length() / avoidCollisionLength, 0.0)
	
	var colDiff = 1.0 - (particle.position.y - global_position.y) / avoidCollisionLength
	colDiff = max(colDiff, 0.0)
	particle.velocity += Vector2.DOWN * colDiff * avoidCollisionForce * delta
	colDiff = 1.0 - (terrainY - particle.position.y) / avoidCollisionLength
	colDiff = max(colDiff, 0.0)
	particle.velocity += Vector2.UP * colDiff * avoidCollisionForce * delta
	
	if particle.position.y > global_position.y:
		particle.velocity += playerDir * playerForceT * avoidCollisionForce
	
	if movementNoise:
		var a = movementNoise.get_noise_2dv(particle.position) * PI * 4.0
		var dir = Vector2.RIGHT.rotated(a)
		particle.velocity += dir * movementMagnitude * delta
	
	particle.velocity = particle.velocity.clamped(movementMaxVelocity)
	var desiredSize = particle.startSize
	if particle.velocity.x < 0.0:
		desiredSize.y = abs(particle.startSize.y) * -1
	else:
		desiredSize.y = abs(particle.startSize.y) * 1
	particle.size = particle.size.linear_interpolate(desiredSize, delta * 2.0)
	
	var angle = particle.velocity.angle()
	particle.rotation = angle

func OffsetOffscreen(particle: Particle) -> void:
	var scCoord = particle.position
	scCoord = canvasTransform.xform(scCoord)
	
	if scCoord.x < -fishSize * 4.0:
		particle.position.x = globalCanvasTransform.origin.x + viewportRect.size.x + fishSize*rand_range(.5, 4.0)
		particle.position.y = global_position.y + randf() * rectSize.y
	elif scCoord.x > viewportRect.size.x + fishSize * 4.0:
		particle.position.x = globalCanvasTransform.origin.x - fishSize*rand_range(.5, 4.0)
		particle.position.y = global_position.y + randf() * rectSize.y
	
	if (particle.position.y - global_position.y) > rectSize.y:
		if randf() < .5:
			particle.position.x = globalCanvasTransform.origin.x - fishSize*rand_range(.5, 4.0)
		else:
			particle.position.x = globalCanvasTransform.origin.x + viewportRect.size.x + fishSize*rand_range(.5, 4.0)




