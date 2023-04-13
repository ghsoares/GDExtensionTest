@tool
extends Node3D
class_name CollisionObjectSpatial2D

enum DisableMode {
	REMOVE,
	MAKE_STATIC,
	KEEP_ACTIVE
}

class ShapeData:
	var owner_id: int
	var xform: Transform2D
	
	class Shape:
		var shape: Shape2D
		var index: int = 0
	
	var shapes: Array[Shape]

	var disabled: bool = false
	var one_way_collision: bool = false
	var one_way_collision_margin: float = 0.0

# -- Private variables --
var m_area: bool = false
var m_rid: RID
var m_callback_lock: int = 0
var m_body_mode: int = PhysicsServer2D.BODY_MODE_STATIC
var m_total_subshapes: int = 0
var m_shapes: Dictionary
var m_shape_id: int = 0
var m_only_update_transform_changes = false

# -- Public variables --
@export var disable_mode: DisableMode = DisableMode.REMOVE:
	get:
		return disable_mode
	set(value):
		if disable_mode == value: return
		
		var disabled: bool = is_inside_tree() and not can_process()

		if disabled:
			__apply_enabled()
		
		disable_mode = value

		if disabled:
			__apply_disabled()

@export_group("Collision", "collision_")
@export_flags_2d_physics var collision_layer: int = 1:
	get: return collision_layer
	set(value):
		collision_layer = value
		if m_area: 
			PhysicsServer2D.area_set_collision_layer(m_rid, value)
		else: 
			PhysicsServer2D.body_set_collision_layer(m_rid, value)

@export_flags_2d_physics var collision_mask: int = 1:
	get: return collision_mask
	set(value):
		collision_mask = value
		if m_area: 
			PhysicsServer2D.area_set_collision_mask(m_rid, value)
		else: 
			PhysicsServer2D.body_set_collision_mask(m_rid, value)

@export var collision_priority: float = 1.0:
	get: return collision_priority
	set(value):
		collision_priority = value
		if not m_area:
			PhysicsServer2D.body_set_collision_priority(m_rid, value)

@export_group("Transform", "transform_")
@export var transform_pixel_size: float = 1.0
@export var transform_invert_y: bool = true

# -- Private functions --
func __apply_disabled() -> void:
	match disable_mode:
		DisableMode.REMOVE:
			if is_inside_tree():
				if m_callback_lock > 0:
					push_error("Disabling a CollisionObject node during a physics callback is not allowed and will cause undesired behavior. Disable with call_deferred() instead.")
				else:
					if m_area:
						PhysicsServer2D.area_set_space(m_rid, RID())
					else:
						PhysicsServer2D.body_set_space(m_rid, RID())
		DisableMode.MAKE_STATIC:
			if not m_area and m_body_mode != PhysicsServer2D.BODY_MODE_STATIC:
				PhysicsServer2D.body_set_mode(m_rid, PhysicsServer2D.BODY_MODE_STATIC)
		DisableMode.KEEP_ACTIVE:
			pass

func __apply_enabled() -> void:
	match disable_mode:
		DisableMode.REMOVE:
			if is_inside_tree():
				var space: RID = get_world_2d().space
				if m_area:
					PhysicsServer2D.area_set_space(m_rid, space)
				else:
					PhysicsServer2D.body_set_space(m_rid, space)
		DisableMode.MAKE_STATIC:
			if not m_area and m_body_mode != PhysicsServer2D.BODY_MODE_STATIC:
				PhysicsServer2D.body_set_mode(m_rid, m_body_mode)
		DisableMode.KEEP_ACTIVE:
			pass

# -- Protected functions --
func _create(rid: RID, area: bool) -> void:
	m_rid = rid
	m_area = area
	set_notify_transform(true)
	m_total_subshapes = 0
	m_only_update_transform_changes = false

	if m_area:
		PhysicsServer2D.area_attach_object_instance_id(m_rid, get_instance_id())
	else:
		PhysicsServer2D.body_attach_object_instance_id(m_rid, get_instance_id())
		PhysicsServer2D.body_set_mode(m_rid, m_body_mode)

func _lock_callback() -> void: m_callback_lock += 1

func _unlock_callback() -> void:
	assert(m_callback_lock != 0)
	m_callback_lock -= 1

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			var gl_transform: Transform2D = get_global_transform_2d()

			if m_area:
				PhysicsServer2D.area_set_transform(m_rid, gl_transform)
			else:
				PhysicsServer2D.body_set_state(m_rid, PhysicsServer2D.BODY_STATE_TRANSFORM, gl_transform)
			
			var disabled: bool = can_process()

			if disabled and disable_mode != DisableMode.REMOVE:
				__apply_disabled()
				
			if not disabled or disable_mode != DisableMode.REMOVE:
				var world_ref: World2D = get_world_2d()
				assert(world_ref != null)
				var space: RID = world_ref.space
				if m_area:
					PhysicsServer2D.area_set_space(m_rid, space)
				else:
					PhysicsServer2D.body_set_space(m_rid, space)

		NOTIFICATION_TRANSFORM_CHANGED:
			if m_only_update_transform_changes: return
			
			var gl_transform: Transform2D = get_global_transform_2d()

			if m_area:
				PhysicsServer2D.area_set_transform(m_rid, gl_transform)
			else:
				PhysicsServer2D.body_set_state(m_rid, PhysicsServer2D.BODY_STATE_TRANSFORM, gl_transform)
		NOTIFICATION_EXIT_TREE:
			var disabled: bool = can_process()

			if not disabled or disable_mode != DisableMode.REMOVE:
				if m_callback_lock > 0:
					push_error("Removing a CollisionObject node during a physics callback is not allowed and will cause undesired behavior. Remove with call_deferred() instead.")
				else:
					if m_area:
						PhysicsServer2D.area_set_space(m_rid, RID())
					else:
						PhysicsServer2D.body_set_space(m_rid, RID())
			
			if disabled and disable_mode != DisableMode.REMOVE:
				__apply_enabled()
		NOTIFICATION_ENABLED:
			__apply_enabled()
		NOTIFICATION_DISABLED:
			__apply_disabled()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if m_shapes.is_empty():
		warnings.push_back("This node has no shape, so it can't collide or interact with other objects.\nConsider adding a CollisionShape2D or CollisionPolygon2D as a child to define its shape.")

	return warnings

func _set_only_update_transform_changes(enable: bool) -> void: 
	m_only_update_transform_changes = enable

func _is_only_update_transform_changes_enabled() -> bool: 
	return m_only_update_transform_changes

func _set_body_mode(mode: int) -> void:
	m_body_mode = mode

# -- Public functions --
func get_world_2d() -> World2D:
	return get_viewport().world_2d

func convert_to_2d(tr: Transform3D) -> Transform2D:
	var ret: Transform2D = Transform2D(
		Vector2(tr.basis.x.x, tr.basis.x.y) / transform_pixel_size,
		Vector2(tr.basis.y.x, tr.basis.y.y) / transform_pixel_size,
		Vector2(tr.origin.x, tr.origin.y) / transform_pixel_size
	)
	if transform_invert_y:
		ret.x.y *= -1
		ret.y.y *= -1
		ret.origin.y *= -1
	return ret

func convert_to_3d(tr: Transform2D) -> Transform3D:
	var ret: Transform3D = Transform3D(
		Vector3(tr.x.x, tr.x.y, 0.0) * transform_pixel_size,
		Vector3(tr.y.x, tr.y.y, 0.0) * transform_pixel_size,
		Vector3(0.0, 0.0, 1.0),
		Vector3(tr.origin.x, tr.origin.y, 0.0) * transform_pixel_size
	)
	if transform_invert_y:
		ret.basis.x.y *= -1
		ret.basis.y.y *= -1
		ret.origin.y *= -1
	return ret

func get_global_transform_2d() -> Transform2D:
	return convert_to_2d(global_transform)

func set_global_transform_2d(tr: Transform2D) -> void:
	var aux: Transform3D = global_transform
	var tr3d: Transform3D = convert_to_3d(tr)
	tr3d.basis.x.z = aux.basis.x.z
	tr3d.basis.y.z = aux.basis.y.z
	tr3d.basis.z = aux.basis.z
	tr3d.origin.z = aux.origin.z
	global_transform = tr3d

func create_shape_owner(owner: Object) -> int:
	var sd: ShapeData = ShapeData.new()
	var id: int = m_shape_id

	sd.owner_id = owner.get_instance_id() if owner else -1

	m_shapes[id] = sd

	return id

func remove_shape_owner(owner: int) -> void:
	assert(m_shapes.has(owner))

	shape_owner_clear_shapes(owner)

	m_shapes.erase(owner)

func shape_owner_set_disabled(owner: int, disabled: bool) -> void:
	assert(m_shapes.has(owner))

	var sd: ShapeData = m_shapes[owner]
	sd.disabled = disabled

	for s in sd.shapes:
		if m_area:
			PhysicsServer2D.area_set_shape_disabled(m_rid, s.index, disabled)
		else:
			PhysicsServer2D.body_set_shape_disabled(m_rid, s.index, disabled)

func is_shape_owner_disabled(owner: int) -> bool: 
	assert(m_shapes.has(owner))
	
	return m_shapes[owner].disabled

func shape_owner_set_one_way_collision(owner: int, enable: bool) -> void: 
	if m_area: return
	
	assert(m_shapes.has(owner))

	var sd: ShapeData = m_shapes[owner]
	sd.one_way_collision = enable
	for s in sd.shapes:
		PhysicsServer2D.body_set_shape_as_one_way_collision(m_rid, s.index, sd.one_way_collision, sd.one_way_collision_margin)

func is_shape_owner_one_way_collision_enabled(owner: int) -> bool:
	assert(m_shapes.has(owner))
	
	return m_shapes[owner].one_way_collision
		
func shape_owner_set_one_way_collision_margin(owner: int, margin: float) -> void:
	if m_area: return
	
	assert(m_shapes.has(owner))

	var sd: ShapeData = m_shapes[owner]
	sd.one_way_collision_margin = margin
	for s in sd.shapes:
		PhysicsServer2D.body_set_shape_as_one_way_collision(m_rid, s.index, sd.one_way_collision, sd.one_way_collision_margin)

func shape_owner_get_one_way_collision_margin(owner: int) -> float:
	assert(m_shapes.has(owner))
	
	return m_shapes[owner].one_way_collision_margin
				
func get_shape_owners(owners: Array[int]) -> void:
	for k in m_shapes.keys():
		owners.push_back(k)

func shape_owner_set_transform(owner: int, transform: Transform2D) -> void:
	assert(m_shapes.has(owner))

	var sd: ShapeData = m_shapes[owner]

	sd.xform = transform
	for s in sd.shapes:
		if m_area:
			PhysicsServer2D.area_set_shape_transform(m_rid, s.index, sd.xform)
		else:
			PhysicsServer2D.body_set_shape_transform(m_rid, s.index, sd.xform)

func shape_owner_get_transform(owner: int) -> Transform2D:
	assert(m_shapes.has(owner))
	
	return m_shapes[owner].xform

func shape_owner_get_owner(owner: int) -> Object:
	assert(m_shapes.has(owner))

	return instance_from_id(m_shapes[owner].owner_id)

func shape_owner_add_shape(owner: int, shape: Shape2D) -> void:
	assert(m_shapes.has(owner))
	assert(shape != null)

	var sd: ShapeData = m_shapes[owner]
	var s: ShapeData.Shape = ShapeData.Shape.new()
	s.index = m_total_subshapes
	s.shape = shape

	if m_area:
		PhysicsServer2D.area_add_shape(m_rid, shape.get_rid(), sd.xform, sd.disabled)
	else:
		PhysicsServer2D.body_add_shape(m_rid, shape.get_rid(), sd.xform, sd.disabled)
	
	sd.shapes.push_back(s)

	m_total_subshapes += 1

func shape_owner_get_shape_count(owner: int) -> int: 
	assert(m_shapes.has(owner))

	return m_shapes[owner].shapes.size()

func shape_owner_get_shape(owner: int, shape: int) -> Shape2D:
	assert(m_shapes.has(owner))
	assert(shape >= 0 and shape < m_shapes[owner].shapes.size())

	return m_shapes[owner].shapes[shape].shape

func shape_owner_get_shape_index(owner: int, shape: int) -> int:
	assert(m_shapes.has(owner))
	assert(shape >= 0 and shape < m_shapes[owner].shapes.size())

	return m_shapes[owner].shapes[shape].index

func shape_owner_remove_shape(owner: int, shape: int) -> void: 
	assert(m_shapes.has(owner))
	assert(shape >= 0 and shape < m_shapes[owner].shapes.size())

	var index_to_remove: int = m_shapes[owner].shapes[shape].index

	if m_area:
		PhysicsServer2D.area_remove_shape(m_rid, index_to_remove)
	else:
		PhysicsServer2D.body_remove_shape(m_rid, index_to_remove)
	
	m_shapes[owner].shapes.remove_at(shape)

	for sd in m_shapes.values():
		for s in sd.shapes:
			if s.index > index_to_remove:
				s.index -= 1
	
	m_total_subshapes -= 1

func shape_owner_clear_shapes(owner: int) -> void: 
	assert(m_shapes.has(owner))

	while shape_owner_get_shape_count(owner) > 0:
		shape_owner_remove_shape(owner, 0)

func shape_find_owner(shape_index: int) -> int: 
	assert(shape_index >= 0 and shape_index < m_total_subshapes)

	for sdk in m_shapes.keys():
		var sd: ShapeData = m_shapes[sdk]
		for s in sd.shapes:
			if s.index == shape_index:
				return sdk
	
	push_error("Can't find owner for shape index %s." % shape_index)

	return -1

func set_body_mode(mode: int) -> void:
	assert(not m_area)

	if m_body_mode == mode: return

	m_body_mode = mode

	if is_inside_tree() and not can_process() && disable_mode == DisableMode.MAKE_STATIC:
		return
	
	PhysicsServer2D.body_set_mode(m_rid, mode)












