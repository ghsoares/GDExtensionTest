extends ParticleSystem

var planet
var viewportRect: Rect2
var canvasTransform: Transform2D
var cameraMotionX: float
var globalCanvasTransform: Transform2D

export (Vector2) var rectSize := Vector2(1024, 768)
export (float) var fishSize = 22.0
export (float) var initialVelocity = 32.0
export (float) var scanRadius = 64.0
export (float) var separationForce = 1.0
export (float) var alignmentForce = 1.5
export (float) var cohesionForce = .5
export (float) var collisionForce = 2.0
export (float) var steering = 8.0
export (int) var numGroups = 4

func UpdateSystem(delta: float) -> void:
	.UpdateSystem(delta)
	viewportRect = get_viewport_rect()
	canvasTransform = get_canvas_transform()
	var currGlobalCanvasTransform = canvasTransform.inverse()
	
	var motion = currGlobalCanvasTransform.origin.x - globalCanvasTransform.origin.x
	
	globalCanvasTransform = currGlobalCanvasTransform

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
	particle.velocity = Vector2.RIGHT.rotated(randf() * PI * 2.0) * initialVelocity

func UpdateParticle(particle: Particle, delta: float) -> void:
	.UpdateParticle(particle, delta)
	OffsetOffscreen(particle)
	BoidBehaviour(particle, delta)
	
	var desiredSize = particle.startSize
	if particle.velocity.x < 0.0:
		desiredSize.y = abs(particle.startSize.y) * -1
	else:
		desiredSize.y = abs(particle.startSize.y) * 1
	particle.size = particle.size.linear_interpolate(desiredSize, delta * 2.0)
	
	var angle = particle.velocity.angle()
	particle.rotation = angle

func BoidBehaviour(particle: Particle, delta: float) -> void:
	var terrain: Terrain = planet.terrain
	var player = planet.player
	var terrainY = terrain.GetTerrainY(particle.position.x)
	
	var desiredDirection := particle.velocity.normalized()
	var currDirection := desiredDirection
	
	var center = particle.position
	var div = 1.0
	
	var thisGroupIdx = particle.idx % numGroups
	
	for p in particles:
		if p == particle: continue
		var otherGroupIdx = p.idx % numGroups
		var pDirection :Vector2= p.velocity.normalized()
		
		var off :Vector2= (particle.position - p.position)
		var dir := off.normalized()
		var t :float= 1.0 - clamp(off.length() / scanRadius, 0.0, 1.0)
		if otherGroupIdx == thisGroupIdx:
			desiredDirection += pDirection * t * alignmentForce
			center += p.position
			div += 1.0
		
		desiredDirection += dir * t * separationForce
	
	center /= div
	var centerDirection = (center - particle.position).normalized()
	
	currDirection += centerDirection * cohesionForce
	
	var topDistance = particle.position.y - global_position.y
	var topT = max(1.0 - topDistance / scanRadius, 0.0)
	
	desiredDirection += Vector2.DOWN * topT * collisionForce * numParticles
	
	var bottomDistance = terrainY - particle.position.y
	var bottomT = max(1.0 - bottomDistance / scanRadius, 0.0)
	
	desiredDirection += Vector2.UP * bottomT * collisionForce * numParticles
	
	var playerOff :Vector2= (particle.position - player.global_position)
	var playerDir := playerOff.normalized()
	var playerT :float = 1.0 - clamp(playerOff.length() / scanRadius, 0.0, 1.0)
	desiredDirection += playerDir * playerT * collisionForce * numParticles
	
	currDirection = currDirection.linear_interpolate(desiredDirection.normalized(), clamp(steering * delta, 0.0, 1.0))
	particle.velocity = particle.velocity.length() * currDirection.normalized()

func OffsetOffscreen(particle: Particle) -> void:
	var scCoord = particle.position
	scCoord = canvasTransform.xform(scCoord)
	
#	if scCoord.x < fishSize * .5:
#		particle.position.x += viewportRect.size.x
#	elif scCoord.x > viewportRect.size.x + fishSize * .5:
#		particle.position.x -= viewportRect.size.x
	
	if scCoord.x < -fishSize * 4.0:
		particle.position.x = globalCanvasTransform.origin.x + viewportRect.size.x + fishSize*rand_range(.5, 4.0)
		particle.position.y = global_position.y + randf() * rectSize.y
	elif scCoord.x > viewportRect.size.x + fishSize * 4.0:
		particle.position.x = globalCanvasTransform.origin.x - fishSize*rand_range(.5, 4.0)
		particle.position.y = global_position.y + randf() * rectSize.y




