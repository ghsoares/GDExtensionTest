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
func distance(x: float, y: float) -> float:
	# Offset
	var ox: float = x
	var oy: float = y

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
	var cx: float = dx * radius
	var cy: float = dy * radius

	# Get height noise (in 0..1 range)
	var hn: float = base_noise.get_noise_2d(cx, cy) * 0.5 + 0.5
	var ht: float = clamp(1.0 - (-d - max(abs(base_noise_range.x), abs(base_noise_range.y))) / 512.0, 0.0, 1.0)
	ht = pow(ht, 2.0)

	# Map to base noise range and subtract to distance
	d -= base_noise_range.x + (base_noise_range.y - base_noise_range.x) * hn * ht

	# d = abs(y) - 1050.0

	# Return the result distance
	return d

## Get the planet bounds
func get_bounds() -> Rect2:
	# Get total radius
	var rad: float = radius + max(base_noise_range.x, base_noise_range.y)

	# Return simple circle bounds
	return Rect2(-Vector2(rad, rad), Vector2(rad * 2, rad * 2))

## Check if bounds intersects
func intersects(pos: Vector2, size: Vector2) -> bool:
	# Get planet radius
	var rad: float = radius + max(base_noise_range.x, base_noise_range.y)

	var cdx: float = abs(pos.x + size.x * 0.5)
	var cdy: float = abs(pos.y + size.y * 0.5)

	if cdx > size.x * 0.5 + rad: return false
	if cdy > size.y * 0.5 + rad: return false

	if cdx <= size.x * 0.5: return true
	if cdy <= size.y * 0.5: return true

	var dsq: float = pow(cdx - size.x * 0.5, 2.0) + pow(cdy - size.y * 0.5, 2.0)

	return dsq <= rad * rad
