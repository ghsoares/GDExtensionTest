tool
extends Control

var chars = []

export (String) var text setget SetText
export (Font) var font
export (float) var magnitude = 4.0
export (float) var speed = 4.0
export (float) var fitHeight = 16.0
export (float) var hAlign = 0.0

func SetText(newText: String) -> void:
	text = newText
	chars.resize(text.length())
	
	for i in range(text.length()):
		var c = chars[i]
		if !c:
			c = {}
		var prevC = c.get("character", null)
		
		if prevC != text[i]:
			c["character"] = text[i]
			c["time"] = 1.0
		
		chars[i] = c

func _process(delta: float) -> void:
	for c in chars:
		c["time"] -= delta * speed
		c["time"] = max(c["time"], 0.0)
	update()

func _draw() -> void:
	if !font: return
	
	var totalSize = font.get_string_size(text)
	totalSize.y = font.get_ascent() - font.get_descent()
	
	var transform = Transform2D.IDENTITY
	var scale = fitHeight / totalSize.y
	transform = transform.scaled(Vector2.ONE * scale)
	transform.origin.y += (totalSize.y / 2.0) * scale
	transform.origin.y += (rect_size.y / 2.0)
	transform.origin.x = lerp(
		transform.origin.x, rect_size.x - totalSize.x * scale, hAlign
	)
	
	draw_set_transform_matrix(transform)
	
	var pos = Vector2.ZERO
	for c in chars:
		var size = font.get_string_size(c["character"])
		var t = ease(c["time"], -2.0)
		pos.y -= t * magnitude
		draw_string(font, pos, c["character"])
		pos.y += t * magnitude
		pos.x += size.x











