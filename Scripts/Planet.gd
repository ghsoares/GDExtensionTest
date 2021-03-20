extends Control

class_name Planet

var generating: bool = false

var generator
var camera

var terrain
var platforms

var debug

# Script to generate the world, must derive from PlanetGenerator as base
export (Script) var planetGenerator
export (Vector2) var size := Vector2(4096, 1024)

func _ready() -> void:
	camera = GameCamera.new()
	debug = PlanetDebug.new()
	
	debug.planet = self
	
	add_child(camera)
	add_child(debug)
	
	Generate()
	pass

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("next_level"):
		Generate()

# Instantiate the PlanetGenerator and calls the generator Generate function
func Generate() -> void:
	if !planetGenerator:
		push_error("No world generator is assigned!")
		return
	
	randomize()
	
	if generating: return
	generating = true
	hide()
	
	if generator:
		generator.queue_free()
	
	rect_size = size
	
	generator = planetGenerator.new()
	
	camera.limit_left = 0.0
	camera.limit_right = size.x
	camera.limit_top = 0.0
	camera.limit_bottom = size.y
	
	generator.planet = self
	
	add_child(generator)
	generator.Generate()
	
	yield(generator, "finished_generation")
	
	generating = false
	show()

