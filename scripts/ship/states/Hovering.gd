extends ShipMovingState
class_name ShipHoveringState

## Called every physics frame
func _process(mode: int, delta: float) -> void:
	# Process parent state and early return
	super._process(mode, delta)
	if queried(): return

	# Process differently based on update mode
	match mode:
		ShipStateMachine.ProcessMode.INTEGRATE_FORCES:
			# Apply turning and thruster
			__process_turn(delta)
			__process_thruster(delta)

		ShipStateMachine.ProcessMode.PHYSICS:
			# Had collision
			if contact_bitmask != 0:
				# Hit on tip of the ship, crashed
				if contact_bitmask & 0b1100 > 0:
					print("Hit tip")
					query("exploded")
					return
				
				# Get max velocity and rotation
				var max_vel: float = target.landing_max_velocity
				var max_rot: float = target.landing_max_rotation

				# Get score velocity and rotation
				var min_vel: float = target.landing_score_velocity
				var min_rot: float = target.landing_score_rotation

				# Get super score velocity and rotation
				var top_vel: float = target.landing_super_score_velocity
				var top_rot: float = target.landing_super_score_rotation

				# Get terrain
				var terrain: LevelTerrain = target.level.terrain

				# Get speed
				var spd: float = body.linear_velocity.length()

				# Too fast, crashed
				if spd > max_vel:
					print("Too fast: %s" % spd)
					query("exploded")
					return
				
				# Get the nearest landing
				var landing: LevelPlanetLanding = terrain.landing_spot(
					body.transform.origin.x,
					body.transform.origin.y
				)

				# There is no landing, crashed
				if landing == null:
					print("No landing")
					query("exploded")
					return
				
				# Get landing transform
				var tr: Transform2D = Utils.transform_3d_to_2d(landing.global_transform)

				# Get local ship transform to landing
				tr = tr.affine_inverse() * body.transform

				# Get distance
				var dist: float = abs(tr.origin.x) - landing.size * 0.5 - target.size.x * 0.5

				# Too far away from landing, crashed
				if dist > 0.0:
					print("Too far away: %s" % dist)
					query("exploded")
					return
					
				# Get ship angle relative to landing
				var a: float = rad_to_deg(tr.x.angle())
				
				# Too much unaligned, crashed
				if abs(a) > max_rot:
					print("Too unaligned: %s" % abs(a))
					query("exploded")
					return
					
				# Get score
				var score: float = remap(abs(a), min_rot, max_rot, 5.0, 0.0)
				score += remap(spd, min_vel, max_vel, 5.0, 0.0)
				score = clamp(score / 2.0, 0.0, 5.0)

				# Superb score
				if (abs(a) < top_rot and spd < top_vel):
					print("Suberb!")
					score *= 2.0
				else:
					print(abs(a), ", ", spd)
				
				# Multiply by 100
				score *= 100
				
				# Multiply by landing score multiplier
				score *= landing.score_multiplier

				# Round to the nearest 10
				score = round(score / 10.0) * 10.0
				
				print(score, ", x", landing.score_multiplier)

				# Landed
				query("landed")

## Update turning forces
func __process_turn(delta: float) -> void:
	# Get turn input
	var input_turn: float = target.input_turn

	# Get turning acceleration
	var turn_acc: float = target.turning_acceleration

	# Convert acceleration and decceleration
	turn_acc = deg_to_rad(turn_acc * -input_turn * delta)

	# Get max turning speed
	var max_turn_speed: float = target.max_turning_speed
	max_turn_speed = deg_to_rad(max_turn_speed)

	# Turn left
	if turn_acc < 0.0:
		body.angular_velocity += clamp(-max_turn_speed - body.angular_velocity, turn_acc, 0.0)
	# Turn right
	elif turn_acc > 0.0:
		body.angular_velocity += clamp(max_turn_speed - body.angular_velocity, 0.0, turn_acc)

## Update thruster forces
func __process_thruster(delta: float) -> void:
	# Get thruster input
	var input_thruster: float = target.input_thruster

	# Get thruster force acceleration
	var thrf_acc: float = target.thruster_acceleration * input_thruster * delta

	# Apply thruster force acceleration
	target.thruster_force = clamp(
		target.thruster_force + thrf_acc,
		0.0, target.max_thruster_force
	)

	# Get current fuel
	var fuel: float = target.fuel

	# Apply thruster while there is fuel
	if fuel > 0.0:
		# Apply thruster force
		body.linear_velocity += body.transform.y * target.thruster_force * body.inverse_mass * delta

		# Use fuel
		target.fuel = max(
			0.0, 
			fuel - target.thruster_force * target.fuel_usage_ratio * delta
		)


