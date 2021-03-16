tool
extends Node2D

class_name WaterPlacer

var world

onready var waterScene = preload("res://Scenes/WaterBody.tscn")

func Generate() -> void:
	var settings = world.settings
	for valley in world.peakValleys.valleys:
		if valley.size.y < min(settings.waterBodiesHeightRange.x, settings.waterBodiesHeightRange.y): continue
		var chances = randf()
		if chances > settings.waterBodiesRate or settings.waterBodiesRate == 0.0: continue
		
		var valleyRect = valley
		var height = rand_range(settings.waterBodiesHeightRange.x, settings.waterBodiesHeightRange.y)
		
		while valleyRect.size.y < height:
			height = rand_range(settings.waterBodiesHeightRange.x, settings.waterBodiesHeightRange.y)
		
		var endY = valleyRect.end.y
		valleyRect.position.y = endY - height
		valleyRect.size.y = height
		
		var intersects = world.platformPlacer.GetPlatformsIntersectingRect(valleyRect)
		if intersects.size() > 0:
			var plat = intersects[0]
			var desired = plat.global_position.y + 2.0
			var off = desired - valleyRect.position.y
			valleyRect.position.y += off
			valleyRect.size.y += abs(off)
		
		var water = waterScene.instance()
		
		water.world = world
		
		water.rect_position = valleyRect.position
		water.rect_size = valleyRect.size
		
		water.rect_position.y += 2
		water.rect_size.y -= 2
		
		water.material = world.settings.waterBodiesMaterial.duplicate()
		
		add_child(water)
		
		water.material.set_shader_param("world_transform", water.get_global_transform())
