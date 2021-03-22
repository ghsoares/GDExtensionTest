extends Control

class_name PlatformsPlacer

var size: Vector2

var spacingRange := Vector2(64.0, 64.0)

var platforms = []
var terrain

onready var platformScene := preload("res://Scenes/Platform.tscn")

func Place() -> void:
	var spacing = rand_range(spacingRange.x, spacingRange.y)
	
	for i in range(5):
		var platform = platformScene.instance()
		
		platform.position.x = spacing
		
		platforms.append(platform)
		
		spacing += rand_range(spacingRange.x, spacingRange.y)
	
	var scoreMultipliers = range(1, 6)
	
	for i in range(5):
		var platform = platforms[i]
		platform.position.x = (platform.position.x / spacing) * size.x
		platform.position.x = floor(platform.position.x)
		platform.position.y = terrain.GetTerrainY(platform.position.x)
		
		platform.scoreMultiplier = scoreMultipliers[randi() % scoreMultipliers.size()]
		platform.size = 20 + (platform.scoreMultiplier - 1) * 8
		
		scoreMultipliers.erase(platform.scoreMultiplier)
		
		add_child(platform)

func GetNearest(x: float):
	var nearest = platforms[0]
	var nearestDist = abs(nearest.position.x - x)
	
	for i in range(1, platforms.size()):
		var plat = platforms[i]
		var dst = abs(plat.position.x - x)
		if dst <= nearestDist:
			nearest = plat
			nearestDist = dst
	
	return nearest









