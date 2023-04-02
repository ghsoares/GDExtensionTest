extends ShipState
class_name ShipMovingState

## Called every physics frame
func _physics_process(delta: float) -> void:
	# Process parent state and early return
	super._physics_process(delta)
	if queried(): return

	# Get ship
	var ship: Ship = target

	# Get current position
	var pos: Vector3 = ship.global_transform.origin

	# Get gravitational field
	var grav: Vector2 = ship.level.terrain.gravity_field(pos.x, pos.y)

	# Apply planet collisions
	_apply_collisions(delta)

	# Apply gravity
	apply_central_force(grav, delta)

## Apply collisions
func _apply_collisions(delta: float) -> void:
	
	pass


