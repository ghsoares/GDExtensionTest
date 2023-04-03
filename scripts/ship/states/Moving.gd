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
	# Box size
	var size: Vector2 = Vector2(3.0, 6.0)

	# Terrain
	var terrain: LevelTerrain = target.level.terrain

	# Get body state
	var body_state: PhysicsDirectBodyState3D = PhysicsServer3D.body_get_direct_state(
		target.get_rid()
	)

	# Number of iterations
	var iterations: int = 4

	# Get each corner
	var corners: Array[Vector2] = [
		Vector2(-size.x, -size.y) * 0.5,
		Vector2( size.x, -size.y) * 0.5,
		Vector2(-size.x,  size.y) * 0.5,
		Vector2( size.x,  size.y) * 0.5
	]

	# Get each corner offset
	var offsets: Array[Vector3] = [
		Vector3.ZERO,
		Vector3.ZERO,
		Vector3.ZERO,
		Vector3.ZERO,
	]

	# Each corner impulses
	var impulses: Array[Vector2] = [
		Vector2.ZERO,
		Vector2.ZERO,
		Vector2.ZERO,
		Vector2.ZERO,
	]

	# Each corner movement
	var move: Array[Vector2] = [
		Vector2.ZERO,
		Vector2.ZERO,
		Vector2.ZERO,
		Vector2.ZERO
	]

	# Each corner index
	var indexes: Array[int] = [
		-1, -1, -1, -1
	]

	# Number of applied corner forces
	var applied: int = 0

	# For each iteration
	for i in iterations:
		applied = 0

		# Transform
		var tr: Transform3D = body_state.transform

		# Velocity
		var lv: Vector3 = body_state.linear_velocity
		var av: Vector3 = body_state.angular_velocity

		# Inverse inertia
		var inv_inertia: Basis = body_state.inverse_inertia_tensor

		# Corner index
		var ci: int = 0

		# For each corner
		for c in corners:
			# Get point
			var p: Vector3 = tr * Vector3(c.x, c.y, 0.0)

			# Get offset
			offsets[ci] = p - tr.origin
			offsets[ci].z = 0.0

			# Get distance
			var d: float = terrain.sdf(p.x, p.y)
			
			# Is inside ground
			if d < 0.0:
				# Get normal
				var n: Vector2 = terrain.derivative(p.x, p.y).normalized()

				# Get velocity
				var v: Vector3 = body_state.get_velocity_at_local_position(
					Vector3(c.x, c.y, 0.0)
				)

				# Get movement
				var m: Vector2 = n * -d

				# Get impulse
				var imp: Vector2 = n * max(-n.dot(Vector2(v.x, v.y)), 0.0)

				# Add movement and impulse
				impulses[applied] = imp
				move[applied] = m
				indexes[applied] = ci

				applied += 1
			
			ci += 1

		# For each applied corner force
		for j in applied:
			# Get corner
			var c: Vector2 = corners[j]

			# Get point
			var p: Vector3 = tr * Vector3(c.x, c.y, 0.0)

			# Get offset
			var o: Vector3 = offsets[indexes[j]]

			# Get factor
			var t: float = (1.0 / applied) * (1.0 / iterations)

			# Get impule
			var _imp: Vector2 = impulses[j]
			var imp: Vector3 = Vector3(_imp.x, _imp.y, 0.0)

			# Get move
			var _m: Vector2 = move[j]
			var m: Vector3 = Vector3(_m.x, _m.y, 0.0)

			# Apply impulses
			lv += imp * Vector3(1.0, 1.0, 0.0) * t
			av += (inv_inertia * o.cross(imp)) * Vector3(0.0, 0.0, 1.0) * t

			# Apply movement
			tr.origin += m * Vector3(1.0, 1.0, 0.0) * t
			tr.basis = Basis.from_euler(
				(inv_inertia * o.cross(m)) * Vector3(0.0, 0.0, 1.0) * t
			) * tr.basis

		lv.z = 0.0
		av.x = 0.0
		av.y = 0.0

		# Apply
		body_state.linear_velocity = lv
		body_state.angular_velocity = av
		body_state.transform = tr

			
