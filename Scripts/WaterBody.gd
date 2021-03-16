tool
extends ColorRect

var world

export (float) var drag = 1.0

onready var area := $Area
onready var col := $Area/Col

func _ready() -> void:
	area.connect("body_entered", self, "OnBodyEntered")
	area.connect("body_exited", self, "OnBodyExited")
	var rectShape := RectangleShape2D.new()
	rectShape.extents = rect_size / 2.0
	col.shape = rectShape
	col.position = rect_size / 2.0

func OnBodyEntered(body) -> void:
	if body is Player:
		if !body.insideWater:
			body.insideWater = self
		world.waterSplashParticles.Splash(body.global_position + Vector2.DOWN * 8.0)

func OnBodyExited(body) -> void:
	if body is Player:
		if !body.insideWater or body.insideWater == self:
			body.insideWater = null
