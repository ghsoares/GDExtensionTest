tool
extends StaticBody2D

var world
var size = 32.0
var height
var scoreMultiplier = 1

export (Vector2) var sizeRange = Vector2(20, 48)

onready var base = $BasePivot/Base
onready var light = $LightPivot/Light
onready var debug = $Debug
onready var scoreMultiplierLabel = $ScoreMultiplierPivot/ScoreMultiplierLabel
onready var col = $Col

func _ready() -> void:
	if !base: return
	
	var h = world.terrain.SampleTerrainHeight(position.x)
	position.y = world.terrain.size.y - h
	
	var t = (scoreMultiplier - 1.0) / 4.0
	
	size = lerp(sizeRange.x, sizeRange.y, 1.0 - t)
	size = round(size)
	
	height = base.rect_size.y
	
	base.rect_position.x = -size / 2.0
	base.rect_size.x = size
	
	light.rect_position.x = -size / 2.0
	light.rect_position.y = -light.rect_size.y
	light.rect_size.x = size
	
	scoreMultiplierLabel.text = str(scoreMultiplier) + "x"
	
	debug.rect_position.x = -size / 2.0
	debug.rect_position.y = -debug.rect_size.y
	debug.rect_size.x = size
	
	var rectShape = RectangleShape2D.new()
	rectShape.extents = Vector2(size, base.rect_size.y) / 2.0
	col.shape = rectShape
	col.position.y = base.rect_size.y / 2.0

func _process(delta: float) -> void:
	if !world or !world.player: return
	var player = world.player
	var localPlayerPos = light.get_global_transform().xform_inv(player.global_position)
	light.material.set_shader_param("playerPosition", localPlayerPos)

func _physics_process(delta: float) -> void:
	if !world or !world.terrain or !world.terrain.planetSettings: return
	
	var h = world.terrain.SampleTerrainHeight(position.x)
	global_position.y = world.terrain.size.y - h
	global_position.y = floor(global_position.y)

func DistX(var pX) -> float:
	return max(abs(pX - position.x) - size / 2.0, 0.0)





