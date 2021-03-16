tool
extends Node2D

class_name PlatformPlacer

export (Vector2) var spacingRange = Vector2(64, 256)

var world
var platforms = []

const NUM_PLATFORMS = 5

onready var platformScene = preload("res://Scenes/Platform.tscn")

func Generate() -> void:
	platforms = []
	
	if !platformScene: return
	
	var spacing = 0.0
	spacing += rand_range(spacingRange.x, spacingRange.y)
	
	for i in range(NUM_PLATFORMS):
		var platform = platformScene.instance()
		platform.name = "Platform " + str(i + 1)
		platform.world = world
		platform.position.x = spacing
		
		platforms.append(platform)
		
		spacing += rand_range(spacingRange.x, spacingRange.y)
	
	var scoreMultipliers = [2, 3, 4, 5]
	
	for i in range(NUM_PLATFORMS):
		platforms[i].position.x = (platforms[i].position.x / spacing) * world.terrain.size.x
		
		platforms[i].position.x = floor(platforms[i].position.x)
		
		if i == NUM_PLATFORMS / 2:
			platforms[i].scoreMultiplier = 1
			continue
		
		var idx = randi() % scoreMultipliers.size()
		var scoreM = scoreMultipliers[idx]
		
		platforms[i].scoreMultiplier = scoreM
		
		scoreMultipliers.remove(idx)
	
	for i in range(NUM_PLATFORMS):
		add_child(platforms[i])

func GetNearestPlatform(var x):
	var nearest = platforms[0]
	var dist = abs(nearest.global_position.x - x)
	
	for i in range(1, NUM_PLATFORMS):
		var thisDist = abs(platforms[i].global_position.x - x)
		if thisDist < dist:
			dist = thisDist
			nearest = platforms[i]
	
	return nearest

func GetPlatformsIntersectingRect(var rect: Rect2):
	var intersecting = []
	for plat in platforms:
		var bounds = Rect2()
		bounds.position = Vector2(plat.global_position.x - plat.size / 2.0, plat.global_position.y)
		bounds.size = Vector2(plat.size, plat.height)
		if rect.intersects(bounds):
			intersecting.append(plat)
	return intersecting

func _process(delta: float) -> void:
	if Engine.editor_hint: update()

func _draw() -> void:
#	var x = get_global_mouse_position().x
#	if !world or !world.terrain: return
#
#	var h = world.terrain.SampleCollisionHeight(x)
#	var normal = world.terrain.SampleNormal(x)
#	var y = world.terrain.size.y - h
#
#	draw_circle(Vector2(x, y), 4.0, Color.yellow)
#	draw_line(Vector2(x, y), Vector2(x, y) + normal * 16.0, Color.yellow)
	pass



