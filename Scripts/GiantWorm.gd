extends StaticBody2D

class_name GiantWorm

var velocity := Vector2.RIGHT * 16.0
var segments = []
var segmentsVelocity := []
var bloodHoles := []
var currentBloodHoleIdx := 0
var currentBloodRate := 0.0
var currentLife := 0.0

var planet
var terrainDustParticleSystem : ParticleSystem

export (int) var numSegments := 8
export (Texture) var segmentsTexture
export (float) var segmentsSpacing := 8.0
export (float) var segmentsSize := 8.0
export (float) var mass := 2.0
export (float) var terrainDustRate := 16.0
export (float) var delayTime := 5.0
export (float) var maxLife := 50.0
export (float) var bloodRate := 8.0

onready var stateMachine := $StateMachine
onready var anim := $Anim
onready var head := $Head
onready var bloodParticleSystem := $Blood

func _ready() -> void:
	for i in range(numSegments):
		var col := CollisionShape2D.new()
		var rectShape := CircleShape2D.new()
		var spr = Sprite.new()
		
		rectShape.radius = segmentsSize / 2.0
		
		col.shape = rectShape
		
		spr.texture = segmentsTexture
		spr.show_behind_parent = true
		col.add_child(spr)
		add_child(col)
		segments.append(col)
		segmentsVelocity.append(Vector2.ZERO)
	segments.push_front(head)
	segmentsVelocity.push_front(Vector2.ZERO)
	InitSegments(Vector2.RIGHT)
	
	stateMachine.root = self
	stateMachine.start()
	
	head.raise()
	
	currentLife = maxLife
	
	bloodParticleSystem.raise()

func InitSegments(dir: Vector2) -> void:
	var pos = Vector2.ZERO
	for i in range(numSegments):
		segments[i].position = pos
		segments[i].rotation = dir.angle()
		pos -= dir * segmentsSpacing
		segmentsVelocity[i] = Vector2.ZERO

func MoveHead(toPosition: Vector2) -> void:
	var delta :Vector2= (toPosition - segments[0].global_position)
	
	var deltaLen = delta.length()
	var i = numSegments - 1
	while i > 0:
		var curr = segments[i]
		var nxt = segments[i-1]
		
		var dir = (nxt.global_position - curr.global_position).normalized()
		
		var deltaT = clamp(deltaLen / segmentsSpacing, 0.0, 1.0)
		curr.global_position = curr.global_position.linear_interpolate(nxt.global_position, deltaT)
		
		curr.global_rotation = dir.angle()
		
		segmentsVelocity[i] = dir * deltaLen
		
		i -= 1
	segmentsVelocity[0] = delta
	
	segments[0].global_position = toPosition
	segments[0].rotation = delta.angle()

func _physics_process(delta: float) -> void:
	ParticlesProcess(delta)

func ParticlesProcess(delta: float) -> void:
	for i in range(numSegments):
		var seg :Node2D= segments[i]
		var terrainY = planet.terrain.GetTerrainY(seg.global_position.x)
		var diff = terrainY - seg.global_position.y
		var vel = segmentsVelocity[i] / delta
		if vel.y > 0.0:
			if diff >= 0.0 and diff <= segmentsSize:
				terrainDustParticleSystem.AddRate(delta * terrainDustRate, {
					"size": Vector2.ONE * 16.0,
					"position": seg.global_position,
					"spread": segmentsSize,
					"velocity": -vel * .25
				})
		else:
			if diff >= -segmentsSize * 3.0 and diff <= 0.0:
				terrainDustParticleSystem.AddRate(delta * terrainDustRate, {
					"size": Vector2.ONE * 16.0,
					"position": seg.global_position,
					"spread": segmentsSize,
					"velocity": Vector2(vel.x, vel.y) * .25
				})
	var numBloodHoles = bloodHoles.size()
	if numBloodHoles > 0:
		currentBloodRate += bloodRate * delta * numBloodHoles
		while currentBloodRate >= 1.0:
			var bloodHole = bloodHoles[currentBloodHoleIdx]
			
			var pos :Vector2 = bloodHole.global_position
			bloodParticleSystem.EmitParticle({
				"position": pos,
				"velocity": bloodHole.global_transform.x
			})
			
			currentBloodHoleIdx += 1
			currentBloodRate -= 1.0
			currentBloodHoleIdx %= numBloodHoles

func Damage(dmg: float) -> void:
	var prevLife = currentLife
	anim.play("Dmg")
	currentLife -= dmg
	
	currentLife = max(currentLife, 0.0)
	
	if currentLife == 0.0 and prevLife > 0.0:
		bloodHoles = BloodHoles(numSegments * 2)

func BloodHoles(amnt: int) -> Array:
	var i = 0
	var holes = []
	while amnt > 0:
		var off = Vector2.RIGHT.rotated(randf() * PI * 2.0) * segmentsSize * .4
		var dir = Vector2.RIGHT.rotated(randf() * PI * 2.0)
		var hole:Node2D = Node2D.new()
		hole.position = off
		hole.rotation = dir.angle()
		
		
		segments[i].add_child(hole)
		
		holes.append(hole)
		
		i += 1
		i %= (numSegments + 1)
		amnt -= 1
	return holes



