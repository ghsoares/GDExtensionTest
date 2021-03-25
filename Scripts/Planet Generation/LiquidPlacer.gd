extends Control

class_name LiquidPlacer

var terrain

var heightRange: Vector2 = Vector2(8.0, 256.0)
var rate: float = .5
var liquidScene := preload("res://Scenes/Liquid.tscn")

func Place() -> Array:
	var valleys = terrain.valleys
	var tryNext := false
	var materials = []
	for valley in valleys:
		if randf() <= rate or tryNext:
			var rect :Rect2= valley
			tryNext = false
			
			var height = rand_range(heightRange.x, heightRange.y)
			if heightRange.x > rect.size.y:
				height = rect.size.y
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
			
			var c :Liquid= liquidScene.instance()
			c.rect_position = rect.position
			c.rect_size = rect.size
			c.material = material.duplicate()
			
			add_child(c)
			c.material.set_shader_param("worldMatrix", c.get_global_transform())
			materials.append(c.material)
	return materials

func Flood(margin: float = 64.0) -> Liquid:
	var mountains = terrain.mountains
	var minY = mountains[0].position.y
	
	for m in mountains:
		minY = min(minY, m.position.y)
	
	minY -= margin
	
	var rect: Rect2 = Rect2(0.0, minY, terrain.size.x, terrain.size.y - minY)
	var c :Liquid= liquidScene.instance()
	c.rect_position = rect.position
	c.rect_size = rect.size
	c.material = material.duplicate()
	
	add_child(c)
	c.material.set_shader_param("worldMatrix", c.get_global_transform())
	return c



