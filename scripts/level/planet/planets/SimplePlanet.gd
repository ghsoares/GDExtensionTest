extends LevelPlanet
class_name SimplePlanet

## Just a simple circular planet with height noise

## Planet radius
@export var radius: float = 64.0

## Planet base noise
@export var base_noise: FastNoiseLite

## Planet base noise range
@export var base_noise_range: Vector2 = Vector2(0.0, 16.0)

## Planet base noise period
@export var base_noise_period: float = 1024.0

## Number of easy landings
@export var easy_landing_count: int = 16

## Number of medium landings
@export var medium_landing_count: int = 8

## Number of hard landings
@export var hard_landing_count: int = 4

## Generate this planet
func generate() -> void:
	# Set base noise seed
	base_noise.seed = randi()

## Sample sdf from this planet
func distance(x: float, y: float) -> float:
	# Get nearest landing spot
	var landing: LevelPlanetLanding = landing_spot(x, y, 256.0)

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

	# Get in circle position
	var cx: float = dx * radius
	var cy: float = dy * radius

	# Get height
	var h: float = radius

	# Get height noise (in 0..1 range)
	var hn: float = base_noise.get_noise_2d(cx / base_noise_period, cy / base_noise_period) * 0.5 + 0.5
	h += base_noise_range.x + (base_noise_range.y - base_noise_range.x) * hn

	# Has a landing spot
	if landing != null:
		# Local transform
		var lox: float = x - landing.transform.origin.x
		var loy: float = y - landing.transform.origin.y
		var lx: float = lox * landing.transform.basis.x.x + loy * landing.transform.basis.x.y
		var ly: float = lox * landing.transform.basis.y.x + loy * landing.transform.basis.y.y

		# Get the size
		var s: float = landing.size

		# Get local height
		var lh: float = landing.transform.basis.y.dot(landing.transform.origin)

		# Get landing height interpolation factor
		var hf: float = clamp(1.0 - (abs(lx) - s) / 32.0, 0.0, 1.0)
		hf = ease(hf, -2.0)

		# Interpolate height
		h = lerp(h, lh, hf)
	
	# Subtract from height
	d -= h

	# Return the result distance
	return d

## Get landing spots
func landing_spots() -> Array[LevelPlanetLanding]:
	var spots: Array[LevelPlanetLanding] = []

	# Get total spots
	var total: int = easy_landing_count + medium_landing_count + hard_landing_count
	spots.resize(total)

	# Each dificulty count
	var easy: int = easy_landing_count
	var medium: int = medium_landing_count
	var hard: int = hard_landing_count

	# For each spot
	for i in total:
		# Instantiate the landing
		var landing: LevelPlanetLanding = landing_scene.instantiate()

		# Get rotation in the planet
		var a: float = (i / float(total)) * TAU

		# Normalized direction
		var dx: float = cos(a)
		var dy: float = sin(a)

		# Get in circle position
		var cx: float = dx * radius
		var cy: float = dy * radius

		# Get height noise (in 0..1 range)
		var hn: float = base_noise.get_noise_2d(cx / base_noise_period, cy / base_noise_period) * 0.5 + 0.5
		
		# Get height
		var h: float = base_noise_range.x + (base_noise_range.y - base_noise_range.x) * hn
		# h += 64.0

		# Get position
		var px: float = cx + dx * h
		var py: float = cy + dy * h

		# Get up and right direction
		var up: Vector2 = Vector2(dx, dy).normalized()
		var rg: Vector2 = Vector2(dy, -dx)

		# Set landing transform
		landing.transform.origin.x = px
		landing.transform.origin.y = py
		landing.transform.basis.x.x = rg.x
		landing.transform.basis.x.y = rg.y
		landing.transform.basis.y.x = up.x
		landing.transform.basis.y.y = up.y

		# Pick a random dificulty
		while true:
			var pick: int = randi() % 3

			if pick == 0 and easy == 0: continue
			if pick == 1 and medium == 0: continue
			if pick == 2 and hard == 0: continue

			# Set the landing size based on dificulty
			match pick:
				0: 
					landing.size = 8.0
					landing.score_multiplier = 3.0
					hard -= 1
				1: 
					landing.size = 12.0
					landing.score_multiplier = 2.0
					medium -= 1
				2: 
					landing.size = 16.0
					landing.score_multiplier = 1.0
					easy -= 1

			break

		# Add to array
		spots[i] = landing

	return spots

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
