extends Node2D

class_name Platform

var size: float = 8.0
var scoreMultiplier: int = 1

onready var base := $Base

func _ready() -> void:
	base.rect_position = Vector2.LEFT * size / 2.0
	base.rect_size.x = size

func GetDistance(var fromX: float):
	return max(abs(fromX - position.x) - size / 2.0, 0.0)


