extends Node3D
class_name LevelTerrain

## The parent level of this terrain
var level: Level

## The chunk manager
var chunk_manager: LevelChunkManager

## Planets root
var planet_root: Node3D

## Current level planets
var planets: Array[LevelPlanet]

## Called when entering the tree
func _enter_tree() -> void:
	# Get the nodes
	level = get_parent()
	chunk_manager = $Chunks
	planet_root = $Planets
	planets.assign(planet_root.get_children())

## Called when ready
func _ready() -> void:
	# Initializes all the current planets
	for planet in planets:
		planet.initialize()
	
	# print(derivative(0.0, 1000.0))

## Main SDF terrain function
func sdf(x: float, y: float, max_distance: float = 8.0) -> float:
	# The total distance
	var d: float = max_distance + 1.0

	# For each planet
	for planet in planets:
		# Get bounds
		var bounds: Rect2 = planet.bounds

		# Check if is too far away
		if bounds.position.x > x + max_distance or bounds.end.x < x - max_distance or bounds.position.y > y + max_distance or bounds.end.y < y - max_distance:
			continue
		
		# Sample the distance
		d = min(d, planet.sdf(x, y))
	
	# Return the distance
	return d

## Main terrain derivative function
func derivative(x: float, y: float, max_distance: float = 8.0) -> Vector2:
	var df: float = 0.01
	var dc: float = sdf(x, y, max_distance)
	var dx: float = sdf(x + df, y, max_distance)
	var dy: float = sdf(x, y + df, max_distance)

	return Vector2(
		(dx - dc) / df, (dy - dc) / df
	)

## Calculate gravity field at position
func gravity_field(x: float, y: float, max_distance: float = 999999.0) -> Vector2:
	# The total gravity
	var g: Vector2 = Vector2.ZERO

	# For each planet
	for planet in planets:
		# Get bounds
		var bounds: Rect2 = planet.bounds

		# Check if is too far away
		if bounds.position.x > x + max_distance or bounds.end.x < x - max_distance or bounds.position.y > y + max_distance or bounds.end.y < y - max_distance:
			continue
		
		# Sample the gravity
		g += planet.gravity_field(x, y)

	# Return the gravity
	return g

## Check if bounds is intersecting
func intersects(start: Vector2, size: Vector2) -> bool:
	var r: Rect2 = Rect2(start, size)

	# For each planet
	for planet in planets:
		# Get bounds
		var bounds: Rect2 = planet.bounds
		
		# Check if intersects
		if bounds.intersects(r, true): return true
	
	return false

## Adds a planet
func add_planet(planet: LevelPlanet) -> void:
	planets.append(planet)

	# Add as child
	planet_root.add_child(planet)

	# Initialize the planet
	planet.initialize()

	# Get the planet bounds
	var bounds: Rect2 = planet.bounds

	# Update chunks in region
	chunk_manager.generate_chunks(bounds.position, bounds.end)

## Removes a planet
func remove_planet(planet: LevelPlanet) -> void:
	planets.erase(planet)

	# Remove as child
	planet_root.remove_child(planet)

	# Get the planet bounds
	var bounds: Rect2 = planet.bounds

	# Update chunks in region
	chunk_manager.generate_chunks(bounds.position, bounds.end)

	# Queue free planet
	planet.queue_free()


