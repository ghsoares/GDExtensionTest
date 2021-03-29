extends State

var curve : Curve2D
var currentT := 0.0
var curveLength := 0.0
var prevPos : Vector2

export (Vector2) var distanceRange := Vector2(128.0, 256.0)
export (float) var velocity := 64.0
export (float) var bezierHandleSize = 4.0

func enter() -> void:
	var player :Player= root.planet.player
	var offX = rand_range(distanceRange.x, distanceRange.y)
	if randf() < .5:
		offX *= -1
	root.global_position.x = player.global_position.x + offX
	var terrainY = root.planet.terrain.GetTerrainY(root.global_position.x)
	root.global_position.y = terrainY + root.segmentsSpacing * 5.0
	CalculateParabola(player.global_position)

func CalculateParabola(toTarget: Vector2) -> void:
	var dir = (toTarget - root.global_position).normalized()
	root.InitSegments(dir)
	
	var offX = (toTarget.x - root.global_position.x);
	
	curve = Curve2D.new()
	
	curve.add_point(
		root.global_position, Vector2.ZERO, Vector2.UP * bezierHandleSize
	)
	curve.add_point(
		toTarget, Vector2.LEFT * bezierHandleSize * sign(offX),
		Vector2.RIGHT * bezierHandleSize * sign(offX)
	)
	curve.add_point(
		Vector2(toTarget.x + offX, root.global_position.y + root.numSegments * root.segmentsSpacing),
		Vector2.UP * bezierHandleSize
	)
	
	currentT = 0.0
	curveLength = curve.get_baked_length()
	
	prevPos = root.global_position

func physics_process() -> void:
	currentT += fixedDeltaTime * velocity
	var point = curve.interpolate_baked(currentT)
	var delta = (point - prevPos)
	
	root.velocity = delta.normalized() * velocity
	root.MoveHead(point)
	
	prevPos = point
	
	if currentT >= curveLength:
		if root.currentLife > 0.0:
			queryState("Hidden")
		else:
			queryState("Dead")
















