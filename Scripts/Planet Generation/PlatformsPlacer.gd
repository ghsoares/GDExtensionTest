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











