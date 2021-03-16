tool
extends Control

class_name TextLabel

enum HAlign {
	LEFT,
	CENTER,
	RIGHT
}
enum VAlign {
	TOP,
	CENTER,
	BOTTOM
}

export (String) var text : String setget SetText
export (float) var fitHeight : float = 16.0 setget SetFitHeight
export (Font) var font : Font setget SetFont
export (HAlign) var hAlign : int setget SetHAlign
export (VAlign) var vAlign : int setget SetVAlign

func SetText(newText: String) -> void:
	text = newText
	update()

func SetFitHeight(newFitHeight: float) -> void:
	fitHeight = newFitHeight
	update()

func SetFont(newFont: Font) -> void:
	font = newFont
	if newFont:
		if !newFont.is_connected("changed", self, "update"):
			newFont.connect("changed", self, "update")
	update()

func SetHAlign(newAlign : int) -> void:
	hAlign = newAlign
	update()

func SetVAlign(newAlign : int) -> void:
	vAlign = newAlign
	update()

func _draw() -> void:
	if !font: return
	
	var textSize = font.get_string_size(text)
	textSize.y = font.get_ascent() - font.get_descent()
	
	var t : Transform2D = Transform2D.IDENTITY
	
	var scale = fitHeight / textSize.y
	t = t.scaled(Vector2.ONE * scale)
	t.origin += Vector2(-1, 1) * (textSize / 2.0) * scale
	
	match vAlign:
		VALIGN_TOP:
			t.origin += Vector2.DOWN * (textSize.y / 2.0) * scale
		VALIGN_CENTER:
			t.origin += Vector2.DOWN * (rect_size.y / 2.0)
		VALIGN_BOTTOM:
			t.origin += Vector2.DOWN * rect_size.y
			t.origin += Vector2.UP * (textSize.y / 2.0) * scale
	
	match hAlign:
		HALIGN_LEFT:
			t.origin += Vector2.RIGHT * (textSize.x / 2.0) * scale
		HALIGN_CENTER:
			t.origin += Vector2.RIGHT * (rect_size.x / 2.0)
		HALIGN_RIGHT:
			t.origin += Vector2.RIGHT * rect_size.x
			t.origin += Vector2.LEFT * (textSize.x / 2.0) * scale
	
	draw_set_transform_matrix(t)
	draw_string(font, Vector2.ZERO, text)














