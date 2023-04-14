@tool
extends CollisionObjectSpatial2D
class_name PhysicsBodySpatial2D

class KinematicCollisionSpatial2D:
	var owner = null
	var result: PhysicsTestMotionResult2D

# -- Protected variables --
var _motion_cache: KinematicCollisionSpatial2D

# -- Protected functions --
func _new(mode: int) -> void:
	super._create(PhysicsServer2D.body_create(), false)
	set_body_mode(mode)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			if _motion_cache:
				_motion_cache.owner = null

func _move(params: PhysicsTestMotionParameters2D, result: PhysicsTestMotionResult2D, test_only: bool = false, cancel_sliding: bool = true) -> bool:
	if m_only_update_transform_changes:
		push_error("Move functions do not work together with 'sync to physics' option. Please read the documentation.")
		
	var colliding: bool = PhysicsServer2D.body_test_motion(get_rid(), params, result)

	if cancel_sliding:
		var motion_len: float = params.motion.length()
		var precision: float = 0.001

		if colliding:
			precision += motion_len * (result.get_collision_unsafe_fraction() - result.get_collision_safe_fraction())

			if result.get_collision_depth() > params.margin + precision:
				cancel_sliding = false

		if cancel_sliding:
			var motion_normal: Vector2
			if motion_len > 0.0:
				motion_normal = params.motion / motion_len
			
			var proj_len: float = result.get_travel().dot(motion_normal)
			var recv: Vector2 = result.travel * motion_normal * proj_len
			var recv_len: float = recv.length()

			# if recv_len < params.margin + precision:
			# 	result.travel = motion_normal * proj_len
			#	result.remainder = params.motion - result.travel
	
	if not test_only:
		var tr: Transform2D = params.from
		tr.origin += result.travel
		set_global_transform_2d(tr)
			
	return colliding

# -- Public functions --
func move_and_collide(motion: Vector2, test_only: bool = false, safe_margin: float = 0.08, recovery_as_collision: bool = false) -> KinematicCollisionSpatial2D:
	var params: PhysicsTestMotionParameters2D = PhysicsTestMotionParameters2D.new()
	params.from = get_global_transform_2d()
	params.motion = motion
	params.margin = safe_margin
	params.recovery_as_collision = recovery_as_collision

	var res: PhysicsTestMotionResult2D = PhysicsTestMotionResult2D.new()

	if _move(params, res, test_only):
		if not _motion_cache or _motion_cache.get_reference_count() > 1:
			_motion_cache = KinematicCollisionSpatial2D.new()
			_motion_cache.onwer = self
		
		_motion_cache.result = res
		return _motion_cache

	return null

func test_move(from: Transform2D, motion: Vector2, collision: KinematicCollisionSpatial2D = null, safe_margin: float = 0.08, recovery_as_collision = false) -> bool:
	assert(is_inside_tree())

	var res: PhysicsTestMotionResult2D = null

	if collision:
		res = collision.result
	else:
		res = PhysicsTestMotionResult2D.new()
	
	var params: PhysicsTestMotionParameters2D = PhysicsTestMotionParameters2D.new()
	params.from = from
	params.motion = motion
	params.margin = safe_margin
	params.recovery_as_collision = recovery_as_collision

	return PhysicsServer2D.body_test_motion(get_rid(), params, res)

func add_collision_exception_with(body) -> void:
	assert(body)
	PhysicsServer2D.body_add_collision_exception(get_rid(), body.get_rid())

func remove_collision_exception_with(body: Node) -> void:
	assert(body)
	PhysicsServer2D.body_remove_collision_exception(get_rid(), body.get_rid())









