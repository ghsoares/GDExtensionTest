extends RigidBody2D

class_name HeightmapRigidbody2D

export var bodyFriction := 1.0
export var bodyAngFriction := 0.5

var planet
var rectShape: RectangleShape2D

var collisionPoints = []
var collidedPoints = []

const COLLISION_SAMPLE_RESOLUTION = 2

func _ready() -> void:
	rectShape = $Col.shape
	SampleCheckPoints()

func SampleCheckPoints() -> void:
	collisionPoints = []
	
	var p0 = rectShape.extents * Vector2(-1, 1)
	var p1 = rectShape.extents * Vector2(-1, -1)
	
	for i in range(4):
		for j in range(COLLISION_SAMPLE_RESOLUTION-1):
			var t = j / float(COLLISION_SAMPLE_RESOLUTION)
			collisionPoints.append(p0.linear_interpolate(p1, t))
		p0 = p1
		p1 = (p1 - Vector2.ONE * .5).rotated(PI * .5) + Vector2.ONE * .5
		
		p0.x = sign(p0.x) * rectShape.extents.x
		p0.y = sign(p0.y) * rectShape.extents.y
		
		p1.x = sign(p1.x) * rectShape.extents.x
		p1.y = sign(p1.y) * rectShape.extents.y

func _physics_process(delta: float) -> void:
	linear_velocity += planet.gravity * delta
	GetCollision(delta)

func _process(delta: float) -> void:
	update()

func GetCollision(delta: float) -> void:
	var terrain = planet.terrain
	
	var collided = false
	
	for p in collisionPoints:
		var worldP = to_global(p)
		var tY = terrain.GetTerrainY(worldP.x)
		var diff = worldP.y - tY
		if diff > 0.0:
			global_position.y -= diff
			collided = true
	
	collidedPoints = []
	
	if collided:
		for p in collisionPoints:
			var worldP = to_global(p)
			var tY = terrain.GetTerrainY(worldP.x)
			var diff = worldP.y - tY
			
			if diff >= -0.08:
				collidedPoints.append(worldP)
		
		var combinedNormal := Vector2.ZERO
		
		for p in collidedPoints:
			var normal = terrain.GetTerrainNormal(p.x)
			var diffPosX = p.x - global_position.x
			var force = atan(diffPosX)
			angular_velocity -= force * delta * PI * 2.0
			combinedNormal += normal
			
			var fric = clamp(delta * bodyFriction, 0, 1)
			var angFric = clamp(delta * bodyAngFriction, 0, 1)
			
			linear_velocity -= linear_velocity * fric
			angular_velocity -= angular_velocity * angFric
		
		if combinedNormal != Vector2.ZERO:
			combinedNormal = combinedNormal.normalized()
			linear_velocity = linear_velocity.slide(combinedNormal)

func _draw() -> void:
	for p in collisionPoints:
		var c = Color.green
		#draw_circle(p, 2.0, c)





