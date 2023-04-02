extends State
class_name ShipState



## Apply impulse to the ship
func apply_impulse(o: Vector2, j: Vector2) -> void:
	# Get ship
	var ship: Ship = target

	# Apply impulse
	ship.apply_impulse(
		Vector3(j.x, j.y, 0.0),
		Vector3(o.x, o.y, target.global_position.z)
	)

## Apply central impulse to the ship
func apply_central_impulse(j: Vector2) -> void:
	# Get ship
	var ship: Ship = target

	# Apply impulse
	ship.apply_central_impulse(
		Vector3(j.x, j.y, 0.0)
	)
	
## Apply force to the ship
func apply_force(o: Vector2, f: Vector2, dt: float) -> void:
	apply_impulse(o, f * dt)

## Apply central force to the ship
func apply_central_force(f: Vector2, dt: float) -> void:
	apply_central_impulse(f * dt)
