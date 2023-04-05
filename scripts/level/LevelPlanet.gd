extends RigidBody5D
class_name LevelPlanet

## The level of this planet
var level: Level

## The chunk manager of this planet
var chunk_manager: LevelPlanetChunkManager

## The bounds of this planet
var bounds: Rect2 = Rect2()

## Planet gravity force
@export var gravity: float = 9.8

## Planet gravity fade range
@export var gravity_fade: Vector2 = Vector2(512.0, 1024.0)

## Called when entering the tree
func _enter_tree() -> void:
	# Get nodes
	chunk_manager = $Chunks

## Initialize this planet
func initialize() -> void:
	bounds = get_bounds()

## Override this function to compute distance in a particular local position
func distance(x: float, y: float) -> float:
	return 0.0

## Computes distance in global space
func global_distance(x: float, y: float) -> float:
	var tr: Transform3D = global_transform
	x -= tr.origin.x
	y -= tr.origin.y
	var gx: float = x * tr.basis.x.x + y * tr.basis.x.y
	var gy: float = x * tr.basis.y.x + y * tr.basis.y.y
	return distance(gx, gy)

## Computes distance derivative in local space
func derivative(x: float, y: float) -> Vector2:
	var df: float = 0.01
	var dc: float = distance(x, y)
	var dx: float = distance(x + df, y)
	var dy: float = distance(x, y + df)
	return Vector2((dx - dc) / df, (dy - dc) / df)

## Computes distance derivative in global space
func global_derivative(x: float, y: float) -> Vector2:
	var tr: Transform3D = global_transform
	x -= tr.origin.x
	y -= tr.origin.y
	var gx: float = x * tr.basis.x.x + y * tr.basis.x.y
	var gy: float = x * tr.basis.y.x + y * tr.basis.y.y
	var d: Vector2 = derivative(gx, gy)
	return Vector2(
		tr.basis.x.x * d.x + tr.basis.x.y * d.x,
		tr.basis.y.x * d.y + tr.basis.y.y * d.y
	)

## Override this function to compute gravity field in a particular position (z = magnitude)
func gravity_field(x: float, y: float) -> Vector2:
	# Calculate offset
	var ox: float = -x
	var oy: float = -y
	
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

## Gets gravity field in global space
func global_gravity_field(x: float, y: float) -> Vector2:
	var tr: Transform3D = global_transform
	x -= tr.origin.x
	y -= tr.origin.y
	var gx: float = x * tr.basis.x.x + y * tr.basis.x.y
	var gy: float = x * tr.basis.y.x + y * tr.basis.y.y
	var g: Vector2 = gravity_field(gx, gy)
	return Vector2(
		tr.basis.x.x * g.x + tr.basis.x.y * g.x,
		tr.basis.y.x * g.y + tr.basis.y.y * g.y
	)

## Get the planet local bounds
func get_bounds() -> Rect2: return Rect2()

## Get the planet global bounds
func get_global_bounds() -> Rect2:
	var tr: Transform2D = Utils.transform_3d_to_2d(global_transform)
	return tr * bounds


