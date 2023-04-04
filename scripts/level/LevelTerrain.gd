extends Node3D
class_name LevelTerrain

## The parent level of this terrain
var level: Level

## Called when entering the tree
func _enter_tree() -> void:
	# Get the nodes
	level = get_parent()

## Main SDF terrain function
func distance(x: float, y: float, max_distance: float = 8.0) -> float:
	# The total distance
	var d: float = max_distance + 1.0

	# Get planets
	var planets: Array[LevelPlanet] = level.planets

	# For each planet
	for planet in planets:
		# Get bounds
		var bounds: Rect2 = planet.bounds

		# Check if is too far away
		if bounds.position.x > x + max_distance or bounds.end.x < x - max_distance or bounds.position.y > y + max_distance or bounds.end.y < y - max_distance:
			continue
		
		# Sample the distance
		d = min(d, planet.global_distance(x, y))
	
	# Return the distance
	return d

## Main terrain derivative function
func derivative(x: float, y: float, max_distance: float = 8.0) -> Vector2:
	var df: float = 0.01
	var dc: float = distance(x, y, max_distance)
	var dx: float = distance(x + df, y, max_distance)
	var dy: float = distance(x, y + df, max_distance)

	return Vector2(
		(dx - dc) / df, 
		(dy - dc) / df
	)

## Calculate gravity field at position
func gravity_field(x: float, y: float, max_distance: float = 999999.0) -> Vector2:
	# The total gravity
	var g: Vector2 = Vector2.ZERO

	# Get planets
	var planets: Array[LevelPlanet] = level.planets

	# For each planet
	for planet in planets:
		# Get bounds
		var bounds: Rect2 = planet.bounds

		# Check if is too far away
		if bounds.position.x > x + max_distance or bounds.end.x < x - max_distance or bounds.position.y > y + max_distance or bounds.end.y < y - max_distance:
			continue
		
		# Sample the gravity
		g += planet.global_gravity_field(x, y)

	# Return the gravity
	return g

## Check if bounds is intersecting
func intersects(start: Vector2, size: Vector2) -> bool:
	var r: Rect2 = Rect2(start, size)

	# Get planets
	var planets: Array[LevelPlanet] = level.planets

	# For each planet
	for planet in planets:
		# Get bounds
		var bounds: Rect2 = planet.bounds
		
		# Check if intersects
		if bounds.intersects(r, true): return true
	
	return false



