extends Control

class_name Planet

var generating: bool = false

var generator
var camera

var terrain

var player

var debug

var gravity := Vector2.DOWN * 49.0
var windSpeed := 0.0

var materialsToUpdate = []

# Script to generate the world, must derive from PlanetGenerator as base
export (Script) var planetGenerator
export (Vector2) var size := Vector2(4096, 1024)

onready var playerScene := preload("res://Scenes/Player.tscn")

func _ready() -> void:
	camera = GameCamera.new()
	debug = PlanetDebug.new()
	
	debug.process_priority = 1
	camera.process_priority = 2
	
	debug.planet = self
	
	add_child(camera)
	add_child(debug)
	
	Generate()
	pass

func _process(delta: float) -> void:
	var playerCurrState = player.stateMachine.currState.name
	var playerTransform = player.get_global_transform()
	if playerCurrState == "Dead":
		playerTransform = Transform2D.IDENTITY
	for mat in materialsToUpdate:
		mat.set_shader_param("playerTransform", playerTransform)

func AddMaterialToUpdate(mat: ShaderMaterial) -> void:
	materialsToUpdate.append(mat)

# Instantiate the PlanetGenerator and calls the generator Generate function
func Generate() -> void:
	if !planetGenerator:
		push_error("No world generator is assigned!")
		return
	
	materialsToUpdate = []
	
	randomize()
	
	if generating: return
	generating = true
	hide()
	
	if generator:
		generator.queue_free()
	if player:
		player.queue_free()
	
	rect_size = size
	
	generator = planetGenerator.new()
	player = playerScene.instance()
	
	player.position = Vector2(size.x / 2.0, -128.0)
	player.planet = self
	
	camera.limit_left = 0.0
	camera.limit_right = size.x
	camera.limit_top = 0.0
	camera.limit_bottom = size.y
	
	generator.planet = self
	
	add_child(player)
	
	add_child(generator)
	
	generator.Generate()
	
	yield(generator, "finished_generation")
	
	generating = false
	show()

