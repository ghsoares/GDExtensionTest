extends RigidBody5D
class_name LevelPlanet

## The level of this planet
var level: Level

## The chunk manager of this planet
var chunk_manager: LevelPlanetChunkManager

## The landing spots root
var landings_root: Node3D

## The landing spots of this planet
var landings: Array[LevelPlanetLanding]

## Landing scene
var landing_scene: PackedScene = ResourceLoader.load("res://scenes/planet/PlanetLanding.tscn")

## Planet surface distance from center
@export var surface: float = 2000.0

## Planet surface fade distance
@export var surface_fade: float = 2000.0

## Planet gravity force
@export var gravity: float = 10.0

## Planet gravity fade distance
@export var gravity_fade: float = 4000.0

## Planet atmosphere density (used for speed drag)
@export var atmosphere_density: float = 1.0

## Called when entering the tree
func _enter_tree() -> void:
	# Get nodes
	chunk_manager = $Chunks
	landings_root = $Landings

## Initialize this planet
func initialize() -> void:
	generate()

	# Get the landing transforms
	var spots: Array[LevelPlanetLanding] = landing_spots()

	# For each spot, add the landing
	for spot in spots:
		# Add as child of landings root
		landings_root.add_child(spot)

		# Add landing
		landings.append(spot)

## Override this function to generate the planet (spawn extra things, etc.)
func generate() -> void: pass

## Override this function to generate a array of landing transforms
func landing_spots() -> Array[LevelPlanetLanding]: return []

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

## Gets gravity field in local space
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
	var mag: float = gravity
	mag *= 1.0 - clamp((d - surface) / gravity_fade, 0.0, 1.0)

	# Return gravity
	return Vector2(dx, dy) * mag

## Gets air density in local space
func air_density(x: float, y: float) -> float:
	# Calculate offset
	var ox: float = -x
	var oy: float = -y
	
	# Calculate distance
	var d: float = sqrt(pow(ox, 2.0) + pow(oy, 2.0))

	# Calculate density
	var dens: float = atmosphere_density
	dens *= 1.0 - clamp((d - surface) / surface_fade, 0.0, 1.0)

	# Return density
	return dens

## Gets the closest landing spot 
func landing_spot(x: float, y: float) -> LevelPlanetLanding:
	# Closest spot and it's distance squared
	var spot: LevelPlanetLanding = null
	var dst: float = 0.0

	# For each landing spot
	for l in landings:
		# Get position
		var pos: Vector3 = l.transform.origin

		# Get offset
		var ox: float = pos.x - x
		var oy: float = pos.y - y

		# Get distance
		var d: float = pow(ox, 2.0) + pow(oy, 2.0)

		# Is current closest
		if spot == null or d < dst:
			spot = l
			dst = d

	return spot

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

## Gets density in global space
func global_air_density(x: float, y: float) -> float:
	var tr: Transform3D = global_transform
	x -= tr.origin.x
	y -= tr.origin.y
	var gx: float = x * tr.basis.x.x + y * tr.basis.x.y
	var gy: float = x * tr.basis.y.x + y * tr.basis.y.y
	return air_density(gx, gy)

## Gets the closest landing spot in global space
func global_landing_spot(x: float, y: float) -> LevelPlanetLanding:
	var tr: Transform3D = global_transform
	x -= tr.origin.x
	y -= tr.origin.y
	var gx: float = x * tr.basis.x.x + y * tr.basis.x.y
	var gy: float = x * tr.basis.y.x + y * tr.basis.y.y
	return landing_spot(gx, gy)

## Get the planet local bounds
func get_bounds() -> Rect2: return Rect2()

## Get the planet global bounds
func get_global_bounds() -> Rect2:
	var tr: Transform2D = Utils.transform_3d_to_2d(global_transform)
	return tr * get_bounds()

## Override this function for quick bounds intersections
func intersects(pos: Vector2, size: Vector2) -> bool:
	return Rect2(pos, size).intersects(get_bounds())



