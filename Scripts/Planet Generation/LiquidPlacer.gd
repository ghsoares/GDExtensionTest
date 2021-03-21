extends Control

class_name LiquidPlacer

var terrain

var heightRange: Vector2 = Vector2(8.0, 256.0)
var rate: float = .5

func Place() -> void:
	var valleys = terrain.valleys
	var tryNext := false
	for valley in valleys:
		if randf() <= rate or tryNext:
			var rect :Rect2= valley
			if rect.size.y < heightRange.x:
				tryNext = true
				continue
			tryNext = false
			
			var height = rand_range(heightRange.x, heightRange.y)
			while height > rect.size.y:
				height = rand_range(heightRange.x, heightRange.y)
			
			var posX = rect.position.x
			var endX = rect.end.x
			
			var middle = Vector2((posX + endX) / 2.0, rect.end.y - height)
			
			var castLeft = terrain.RayIntersect(middle, Vector2.LEFT)
			var castRight = terrain.RayIntersect(middle, Vector2.RIGHT)
			
			if castLeft:
				posX = castLeft.point.x
			if castRight:
				endX = castRight.point.x
			
			if posX > endX:
				var temp = posX
				posX = endX
				endX = temp
			
			rect.position.x = posX
			rect.size.x = (endX - posX)
			
			rect.position.y = rect.end.y - height
			rect.size.y = terrain.size.y - rect.position.y
			
			var c := ColorRect.new()
			c.rect_position = rect.position
			c.rect_size = rect.size
			c.material = material.duplicate()
			
			add_child(c)
			material.set_shader_param("worldMatrix", get_global_transform())


