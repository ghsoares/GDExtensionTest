extends Node2D

class_name Platform

var planet

var size: float = 8.0
var scoreMultiplier: int = 1

onready var base := $Base/Col
onready var light := $Light/Col
onready var lightMat :ShaderMaterial = $Light/Col.material

func _ready() -> void:
	base.rect_position = Vector2.LEFT * size / 2.0
	base.rect_size.x = size
	light.rect_position.x = -size / 2.0
	light.rect_size.x = size

func GetDistance(var fromX: float):
	return max(abs(fromX - position.x) - size / 2.0, 0.0)

func _process(delta: float) -> void:
	var playerPos = planet.player.global_position
	playerPos = light.get_global_transform().xform_inv(playerPos)
	lightMat.set_shader_param("localPlayerPosition", playerPos)
