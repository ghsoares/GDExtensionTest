extends ShipState
class_name ShipMovingState

## Current contact bitmask
var contact_bitmask: int = 0

## Current contact positions
var contact_positions: Array[Vector2] = []

## Called every physics frame
func _process(mode: int, delta: float) -> void:
	# Process parent state and early return
	super._process(mode, delta)
	if queried(): return

	# Process differently based on update mode
	match mode:
		ShipStateMachine.ProcessMode.INTEGRATE_FORCES:
			# Get ship
			var ship: Ship = target

			# Get current position
			var pos: Vector2 = ship.get_transform_2d().origin

			# Get gravitational field
			var grav: Vector2 = ship.level.terrain.gravity_field(pos.x, pos.y)

			# Apply gravity
			apply_central_force(grav)

			# Apply drag
			__apply_drag(delta)

			# Apply planet collisions
			__apply_planet_collisions(delta)
			
## Apply collisions
func __apply_planet_collisions(delta: float) -> void:
	# Ship size
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
		Vector2( size.x,  size.y) * 0.5,
		Vector2(-size.x,  size.y) * 0.5
	]

	# Number of corners
	var count: int = corners.size()

	# Resize contact positions
	contact_positions.resize(count)

	# For each iteration
	for i in iterations:
		# Total impulses
		var imp_lv: Vector2 = Vector2.ZERO
		var imp_av: float = 0.0
		var imp_pos: Vector2 = Vector2.ZERO
		var imp_rot: float = 0.0
		var imp_count: int = 0
		contact_bitmask = 0

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

			# Set contact position
			contact_positions[j] = p
			
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
					imp_forc += tg * -tgv * clamp(32.0 * delta, 0.0, 1.0)
					
				# Apply to both position and rotation
				imp_pos += imp_move
				imp_rot += inv_inertia * o.cross(imp_move / nm)

				# Apply to both linear and angular velocity
				imp_lv += imp_forc * nm
				imp_av += inv_inertia * o.cross(imp_forc * nm)
				
				# Add impulse count
				imp_count += 1

				# Set corner bitmap
				contact_bitmask |= 1 << j

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

## Apply drag forces 
func __apply_drag(delta: float) -> void:
	# Ship size
	var size: Vector2 = target.size

	# Get body
	var body: PhysicsDirectBodyState2D = target.get_body_state()

	# Get terrain
	var terrain: LevelTerrain = target.level.terrain

	# Get air density
	var air_dens: float = terrain.air_density(
		body.transform.origin.x, 
		body.transform.origin.y
	)
	
	# Each corner local position
	var corners: Array[Vector2] = [
		Vector2(-size.x, -size.y) * 0.5,
		Vector2( size.x, -size.y) * 0.5,
		Vector2( size.x,  size.y) * 0.5,
		Vector2(-size.x,  size.y) * 0.5
	]

	# Total impulses
	var imp_lv: Vector2 = Vector2.ZERO
	var imp_av: float = 0.0

	# Get transform
	var tr: Transform2D = body.transform

	# For each corner
	for c in corners:
		# Get offset
		var o: Vector2 = tr.basis_xform(c)

		# Get velocity
		var v1: Vector2 = body.linear_velocity
		var v2: Vector2 = body.get_velocity_at_local_position(o)

		# Drag force
		var f1: Vector2 = -v1 * clamp(air_dens * delta, 0.0, 1.0)
		var f2: Vector2 = -v2 * clamp(air_dens * delta, 0.0, 1.0)

		# Apply impulses
		imp_lv += f1 * body.inverse_mass
		imp_av += o.cross(f2) * body.inverse_inertia
	
	# Apply forces
	body.linear_velocity += imp_lv * (1.0 / corners.size())
	body.angular_velocity += imp_av * (1.0 / corners.size())


