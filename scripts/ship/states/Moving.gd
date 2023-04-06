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
		var grav: Vector2 = ship.level.terrain.gravity_field(pos.x, pos.y, target.mass)
		# print(grav)

		# Apply turning and thruster
		__process_turn(delta)
		__process_thruster(delta)

		# Apply gravity
		apply_central_force(grav)

		# Apply planet collisions
		__apply_planet_collisions(delta)

## Apply collisions
func __apply_planet_collisions(delta: float) -> void:
	# Box size
	var size: Vector2 = target.size

	# Terrain
	var terrain: LevelTerrain = target.level.terrain

	# Number of iterations
	var iterations: int = 4

	# Delta for each iteration
	var dt: float = delta / iterations

	# Each corner local position
	var corners: Array[Vector2] = [
		Vector2(-size.x, -size.y) * 0.5,
		Vector2( size.x, -size.y) * 0.5,
		Vector2( size.x,  0.0) * 0.5,
		Vector2( size.x,  size.y) * 0.5,
		Vector2(-size.x,  size.y) * 0.5,
		Vector2(-size.x,  0.0) * 0.5
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
				# Get normal and tangent
				var n: Vector2 = terrain.derivative(p.x, p.y).normalized()
				var tg: Vector2 = Vector2(n.y, -n.x)

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

				# Get tangential velocity
				var tgv: float = tg.dot(v)

				# Static friction
				if abs(tgv) < 1.0:
					imp_forc += tg * -tgv
				# Dynamic friction
				else:
					imp_forc += tg * -tgv * clamp(8.0 * delta, 0.0, 1.0)
					
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

	# if contact_bitmap == 3:
	# 	print("On Ground!")

	# print(Utils.int_to_bin_string(contact_bitmap, 4, false))

## Update turning forces
func __process_turn(delta: float) -> void:
	# Get turn input
	var input_turn: float = target.input_turn

	# Get body
	var body: PhysicsDirectBodyState2D = target.get_body_state()

	# Get turning acceleration
	var turn_acc: float = target.turning_acceleration * -input_turn * delta
	turn_acc = deg_to_rad(turn_acc)

	# Get turning decceleration
	var turn_dec: float = target.turning_decceleration * delta
	turn_dec = deg_to_rad(turn_dec)

	# Get max turning speed
	var max_turn_speed: float = target.max_turning_speed
	max_turn_speed = deg_to_rad(max_turn_speed)

	# Apply decceleration
	body.angular_velocity += clamp(-body.angular_velocity, -turn_dec, turn_dec)

	# Turn left
	if turn_acc < 0.0:
		body.angular_velocity += clamp(-max_turn_speed - body.angular_velocity, turn_acc, 0.0)
	# Turn right
	elif turn_acc > 0.0:
		body.angular_velocity += clamp(max_turn_speed - body.angular_velocity, 0.0, turn_acc)
	
	# # Get desired angular velocity
	# var desired: float = target.max_turning_speed * -input_turn
	# desired = deg_to_rad(desired)

	# # Get angular acceleration
	# var acc: float = target.turning_acceleration * delta
	# acc = deg_to_rad(acc)

	# # Apply acceleration
	# body.angular_velocity += clamp(
	# 	desired - body.angular_velocity, 
	# 	-acc, 
	# 	acc
	# )

## Update thruster forces
func __process_thruster(delta: float) -> void:
	# Get thruster input
	var input_thruster: float = target.input_thruster

	# Get body
	var body: PhysicsDirectBodyState2D = target.get_body_state()

	# Get thruster force acceleration
	var thrf_acc: float = target.thruster_acceleration * input_thruster * delta

	# Apply thruster force acceleration
	target.thruster_force = clamp(
		target.thruster_force + thrf_acc,
		0.0, target.max_thruster_force
	)
	
	# Get thruster force
	var force: Vector2 = body.transform.y * target.thruster_force

	# Apply thruster force
	body.apply_central_force(force)

