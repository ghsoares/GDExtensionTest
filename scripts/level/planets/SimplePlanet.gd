extends LevelPlanet
class_name SimplePlanet

## Just a simple circular planet with height noise

## Planet radius
@export var radius: float = 64.0

## Planet base noise
@export var base_noise: FastNoiseLite

## Planet base noise range
@export var base_noise_range: Vector2 = Vector2(0.0, 16.0)

## Sample sdf from this planet
func sdf(x: float, y: float) -> float:
	# Offset
	var ox: float = x - center.x
	var oy: float = y - center.y

	# Point distance
	var d: float = sqrt(
		pow(ox, 2.0) +
		pow(oy, 2.0)
	)

	# Normalized direction
	var dx: float = ox / d if d > 0.0 else ox
	var dy: float = oy / d if d > 0.0 else oy

	# Convert point distance to sdf
	d -= radius

	# Get in circle position
	var cx: float = center.x + dx * radius
	var cy: float = center.y + dy * radius

	# Get height noise (in 0..1 range)
	var hn: float = base_noise.get_noise_2d(cx, cy) * 0.5 + 0.5

	# Map to base noise range and subtract to distance
	d -= base_noise_range.x + (base_noise_range.y - base_noise_range.x) * hn

	# Return the result distance
	return d

## Get the planet bounds
func get_bounds() -> Rect2:
	# Get total radius
	var rad: float = radius + max(base_noise_range.x, base_noise_range.y)

	# Return simple circle bounds
	return Rect2(center - Vector2(rad, rad), Vector2(rad * 2, rad * 2))


