extends ShipState
class_name ShipMovingState

## Called every physics frame
func _process(mode: int, delta: float) -> void:
	# Process parent state and early return
	super._process(mode, delta)
	if queried(): return

	# Integrate forces
	if mode == ShipStateMachine.ProcessMode.INTEGRATE_FORCES:
		# Get ship
		var ship: Ship = target

		# Get current position
		var pos: Vector2 = ship.get_transform_2d().origin

		# Get gravitational field
		var grav: Vector2 = ship.level.terrain.gravity_field(pos.x, pos.y)

		# Apply planet collisions
		_apply_collisions(delta)

		# Apply gravity
		apply_central_force(grav)

## Apply collisions
func _apply_collisions(delta: float) -> void:
	# Box size
	var size: Vector2 = target.size

	# Terrain
	var terrain: LevelTerrain = target.level.terrain

	# Number of iterations
	var iterations: int = 4

	# Delta for each iteration
	var dt: float = delta / iterations

	# Get each corner
	var corners: Array[Vector2] = [
		Vector2(-size.x, -size.y) * 0.5,
		Vector2( size.x, -size.y) * 0.5,
		Vector2( size.x,  size.y) * 0.5,
		Vector2(-size.x,  size.y) * 0.5
	]

	# Number of corners
	var count: int = corners.size()

	# Contact bitmap
	var contact_bitmap: int = 0

	# For each iteration
	for i in iterations:
		# Total impulses
		var imp_lv: Vector2 = Vector2.ZERO
		var imp_av: float = 0.0
		var imp_pos: Vector2 = Vector2.ZERO
		var imp_rot: float = 0.0
		var imp_count: int = 0
		contact_bitmap = 0

		# Get transform
		var tr: Transform2D = target.get_transform_2d()

		# Inverse inertia and mass
		var inv_mass: float = body_state.inverse_mass
		var inv_inertia: float = body_state.inverse_inertia

		# For each corner
		for j in count:
			# Get corner
			var c: Vector2 = corners[j]

			# Get point
			var p: Vector2 = tr * c
			
			# Get offset
			var o: Vector2 = tr.basis_xform(c)

			# Get distance
			var d: float = terrain.distance(p.x, p.y)

			# Inside ground
			if d < 0.0:
				# Get normal
				var n: Vector2 = terrain.derivative(p.x, p.y).normalized()

				# Calculate normal mass, to apply to impulse force
				var rn: float = o.dot(n)
				var kn: float = inv_mass + inv_inertia * (o.dot(o) - rn * rn)
				var nm: float = 1.0 / kn

				# Get velocity
				var v: Vector2 = body_state.get_velocity_at_local_position(o)

				# Move and force impulse
				var imp_move: Vector2 = Vector2.ZERO
				var imp_forc: Vector2 = Vector2.ZERO

				# Move from ground
				imp_move += n * -d * nm

				# Slide velocity
				imp_forc += n * max(-n.dot(v), 0.0) * iterations * 1.0

				# Friction
				imp_forc += -(v - n * n.dot(v)) * min(-8.0 * dt, 1.0)
					
				# Apply to both position and rotation
				imp_pos += imp_move
				imp_rot += inv_inertia * o.cross(imp_move) / inv_mass

				# Apply to both linear and angular velocity
				imp_lv += imp_forc * nm
				imp_av += inv_inertia * o.cross(imp_forc * nm)
				
				# Add impulse count
				imp_count += 1

				# Set corner bitmap
				contact_bitmap |= 1 << j

		# Has impulse to apply
		if imp_count > 0:
			# Impulse factor
			var t: float = (1.0 / imp_count) * (1.0 / iterations)

			# Apply impulses
			body_state.linear_velocity += imp_lv * t
			body_state.angular_velocity += imp_av * t
			tr.origin += imp_pos * t
			tr.x = tr.x.rotated(imp_rot * t)
			tr.y = tr.y.rotated(imp_rot * t)
			body_state.transform = tr

			imp_lv = Vector2.ZERO
			imp_av = 0.0
			imp_pos = Vector2.ZERO
			imp_rot = 0.0
			imp_count = 0

	# print(Utils.int_to_bin_string(contact_bitmap, 4, false))

