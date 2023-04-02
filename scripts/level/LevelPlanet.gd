extends Node
class_name LevelPlanet

## The bounds of this planet
var bounds: Rect2 = Rect2()

## Planet center
@export var center: Vector2 = Vector2()

## Planet gravity force
@export var gravity: float = 9.8

## Planet gravity fade range
@export var gravity_fade: Vector2 = Vector2(512.0, 1024.0)

## Initialize this planet
func initialize() -> void:
	bounds = get_bounds()

## Override this function to compute distance in a particular position
func sdf(x: float, y: float) -> float:
	return 0.0

## Override this function to compute gravity field in a particular position (z = magnitude)
func gravity_field(x: float, y: float) -> Vector2:
	# Calculate offset
	var ox: float = center.x - x
	var oy: float = center.y - y
	
	# Calculate distance
	var d: float = sqrt(pow(ox, 2.0) + pow(oy, 2.0))

	# Calculate direction
	var dx: float = ox / d if d > 0.0 else ox
	var dy: float = oy / d if d > 0.0 else oy

	# Calculate magnitude
	var mag: float = (d - gravity_fade.x) / (gravity_fade.y - gravity_fade.x)
	mag = clamp(1.0 - mag, 0.0, 1.0) * gravity

	# Return gravity
	return Vector2(dx, dy) * mag

## Get the planet bounds
func get_bounds() -> Rect2: return Rect2()




