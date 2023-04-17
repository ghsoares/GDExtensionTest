@tool
extends _PhysicsBodySpatial2D
class_name _RigidBodySpatial2D

enum FreezeMode {
	STATIC, KINEMATIC
}

enum CenterOfMassMode {
	AUTO, CUSTOM
}
enum DampMode {
	COMBINE, REPLACE
}

enum CCDMode {
	DISABLED, CAST_RAY, CAST_SHAPE
}

class RigidBodySpatial2D_RemoveAction:
	var rid: RID
	var body_id: int
	var pair: Vector3i

class BodyState:
	var rid: RID
	var in_scene: bool
	var shapes: Array[Vector3i]

class ContactMonitor:
	var locked: bool = false
	var body_map: Dictionary

class RigidBodySpatial2DInOut:
	var rid: RID
	var id: int
	var shape: int = 0
	var local_shape: int = 0

# -- Private variables --
var m_mass: float = 1.0
var m_inertia: float = 0.0
var m_center_of_mass_mode: CenterOfMassMode = CenterOfMassMode.AUTO
var m_center_of_mass: Vector2 = Vector2.ZERO
var m_physics_material_override: PhysicsMaterial = null
var m_gravity_scale: float = 1.0
var m_custom_integrator: bool = false
var m_continuous_cd: CCDMode = CCDMode.DISABLED
var m_max_contacts_reported: int = 0
var m_contact_monitor: ContactMonitor = null
var m_sleeping: bool = false
var m_can_sleep: bool = true
var m_lock_rotation: bool = false
var m_freeze: bool = false
var m_freeze_mode: FreezeMode = FreezeMode.STATIC
var m_linear_velocity: Vector2 = Vector2.ZERO
var m_linear_damp_mode: DampMode = DampMode.COMBINE
var m_linear_damp: float = 0.0
var m_angular_velocity: float = 0.0
var m_angular_damp_mode: DampMode = DampMode.COMBINE
var m_angular_damp: float = 0.0
var m_constant_force: Vector2 = Vector2.ZERO
var m_constant_torque: float = 0.0

# -- Public variables --
@export var mass: float = 1.0:
	get: return m_mass
	set(value):
		assert(value > 0)
		m_mass = value
		PhysicsServer2D.body_set_param(get_rid(), PhysicsServer2D.BODY_PARAM_MASS, m_mass)

@export var inertia: float = 0.0:
	get: return m_inertia
	set(value):
		assert(value >= 0)
		m_inertia = value
		PhysicsServer2D.body_set_param(get_rid(), PhysicsServer2D.BODY_PARAM_INERTIA, m_inertia)

@export var center_of_mass_mode: CenterOfMassMode = CenterOfMassMode.AUTO:
	get: return m_center_of_mass_mode
	set(value):
		if m_center_of_mass_mode == value: return
		m_center_of_mass_mode = value

		match m_center_of_mass_mode:
			CenterOfMassMode.AUTO:
				m_center_of_mass = Vector2()
				PhysicsServer2D.body_reset_mass_properties(get_rid())
				if m_inertia != 0.0:
					PhysicsServer2D.body_set_param(get_rid(), PhysicsServer2D.BODY_PARAM_INERTIA, m_inertia)
			CenterOfMassMode.CUSTOM:
				PhysicsServer2D.body_set_param(get_rid(), PhysicsServer2D.BODY_PARAM_CENTER_OF_MASS, m_center_of_mass)

@export var center_of_mass: Vector2 = Vector2.ZERO:
	get: return m_center_of_mass
	set(value):
		if m_center_of_mass == value: return

		assert(m_center_of_mass_mode == CenterOfMassMode.CUSTOM)
		m_center_of_mass = value

		PhysicsServer2D.body_set_param(
			get_rid(), 
			PhysicsServer2D.BODY_PARAM_CENTER_OF_MASS, 
			tr2d() * m_center_of_mass
		)

@export var physics_material_override: PhysicsMaterial:
	get: return m_physics_material_override
	set(value):
		if m_physics_material_override:
			if m_physics_material_override.changed.is_connected(__reload_physics_characteristics):
				m_physics_material_override.changed.disconnect(__reload_physics_characteristics)
		
		m_physics_material_override = value

		if m_physics_material_override:
			m_physics_material_override.changed.connect(__reload_physics_characteristics)
		
		__reload_physics_characteristics()

@export var gravity_scale: float = 1.0:
	get: return m_gravity_scale
	set(value):
		m_gravity_scale = value
		PhysicsServer2D.body_set_param(get_rid(), PhysicsServer2D.BODY_PARAM_GRAVITY_SCALE, m_gravity_scale)

@export var custom_integrator: bool = false:
	get: return m_custom_integrator
	set(value):
		if m_custom_integrator == value: return
		m_custom_integrator = value
		PhysicsServer2D.body_set_omit_force_integration(get_rid(), m_custom_integrator)

@export var continuous_cd: CCDMode = CCDMode.DISABLED:
	get: return m_continuous_cd
	set(value):
		m_continuous_cd = value
		PhysicsServer2D.body_set_continuous_collision_detection_mode(get_rid(), int(m_continuous_cd))

@export var max_contacts_reported: int = 0:
	get: return m_max_contacts_reported
	set(value):
		m_max_contacts_reported = value
		PhysicsServer2D.body_set_max_contacts_reported(get_rid(), m_max_contacts_reported)

@export var contact_monitor: bool = false:
	get: return m_contact_monitor != null
	set(value):
		if value == (m_contact_monitor != null): return
		
		if value:
			m_contact_monitor = ContactMonitor.new()
			m_contact_monitor.locked = false
		else:
			assert(not m_contact_monitor.locked, "Can't disable contact monitoring during in/out callback. Use call_deferred(\"set_contact_monitor\", false) instead.")

			for bsk in m_contact_monitor.body_map.keys():
				var bs: BodyState = m_contact_monitor.body_map[bsk]

				var obj: Object = instance_from_id(bsk)
				var node: Node = obj as Node

				if node:
					node.tree_entered.disconnect(__body_enter_tree)
					node.tree_exited.disconnect(__body_exit_tree)
			
			m_contact_monitor = null

@export var sleeping: bool = false:
	get: return m_sleeping
	set(value):
		m_sleeping = value
		PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_SLEEPING, m_sleeping)

@export var can_sleep: bool = true:
	get: return m_can_sleep
	set(value):
		m_can_sleep = value
		PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_CAN_SLEEP, m_can_sleep)

@export var lock_rotation: bool = false:
	get: return m_lock_rotation
	set(value):
		if m_lock_rotation == value: return
		
		m_lock_rotation = value
		_apply_body_mode()

@export var freeze: bool = false:
	get: return m_freeze
	set(value):
		if m_freeze == value: return
		
		m_freeze = value
		_apply_body_mode()

@export var freeze_mode: FreezeMode = FreezeMode.STATIC:
	get: return m_freeze_mode
	set(value):
		if m_freeze_mode == value: return
		
		m_freeze_mode = value
		_apply_body_mode()

@export_group("Linear", "linear_")
@export var linear_velocity: Vector2 = Vector2.ZERO:
	get: return m_linear_velocity
	set(value):
		m_linear_velocity = value
		PhysicsServer2D.body_set_state(
			get_rid(), 
			PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, 
			itr2d() * m_linear_velocity
		)

@export var linear_damp_mode: DampMode = DampMode.COMBINE:
	get: return m_linear_damp_mode
	set(value):
		m_linear_damp_mode = value
		PhysicsServer2D.body_set_param(get_rid(), PhysicsServer2D.BODY_PARAM_LINEAR_DAMP_MODE, m_linear_damp_mode)

@export var linear_damp: float = 0.0:
	get: return m_linear_damp
	set(value):
		assert(value >= -1)
		m_linear_damp = value
		PhysicsServer2D.body_set_param(get_rid(), PhysicsServer2D.BODY_PARAM_LINEAR_DAMP, m_linear_damp)

@export_group("Angular", "angular_")
@export var angular_velocity: float = 0.0:
	get: return m_angular_velocity
	set(value):
		m_angular_velocity = value
		PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, m_angular_velocity)

@export var angular_damp_mode: DampMode = DampMode.COMBINE:
	get: return m_angular_damp_mode
	set(value):
		m_angular_damp_mode = value
		PhysicsServer2D.body_set_param(get_rid(), PhysicsServer2D.BODY_PARAM_ANGULAR_DAMP_MODE, m_angular_damp_mode)

@export var angular_damp: float = 0.0:
	get: return m_angular_damp
	set(value):
		assert(value >= -1)
		m_angular_damp = value
		PhysicsServer2D.body_set_param(get_rid(), PhysicsServer2D.BODY_PARAM_ANGULAR_DAMP, m_angular_damp)

@export_group("Constant Forces", "constant_")
@export var constant_force: Vector2 = Vector2.ZERO:
	get: return itr2d() * PhysicsServer2D.body_get_constant_force(get_rid())
	set(value):
		PhysicsServer2D.body_set_constant_force(get_rid(), value)

@export var constant_torque: float = 0.0:
	get: return PhysicsServer2D.body_get_constant_torque(get_rid())
	set(value):
		PhysicsServer2D.body_set_constant_torque(get_rid(), value)

# -- Signals --
signal body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int)
signal body_shape_exited(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int)
signal body_entered(body: Node)
signal body_exited(body: Node)
signal sleeping_state_changed()

# -- Private functions --
func __reload_physics_characteristics() -> void:
	if m_physics_material_override:
		PhysicsServer2D.body_set_param(get_rid(), PhysicsServer2D.BODY_PARAM_BOUNCE, m_physics_material_override.bounce)
		PhysicsServer2D.body_set_param(get_rid(), PhysicsServer2D.BODY_PARAM_FRICTION, m_physics_material_override.friction)
	else:
		PhysicsServer2D.body_set_param(get_rid(), PhysicsServer2D.BODY_PARAM_BOUNCE, 0)
		PhysicsServer2D.body_set_param(get_rid(), PhysicsServer2D.BODY_PARAM_FRICTION, 1)

func __body_enter_tree(id: int) -> void: 
	var obj: Object = instance_from_id(id)
	var node: Node = obj as Node
	assert(node)
	assert(m_contact_monitor)

	var bs: BodyState = m_contact_monitor.body_map.get(id)
	assert(bs)
	assert(!bs.in_scene)

	m_contact_monitor.locked = true

	bs.in_scene = true
	body_entered.emit(node)

	for s in bs.shapes:
		body_shape_entered.emit(bs.rid, node, s.x, s.y)

	m_contact_monitor.locked = false

func __body_exit_tree(id: int) -> void:
	var obj: Object = instance_from_id(id)
	var node: Node = obj as Node
	assert(node)
	assert(m_contact_monitor)

	var bs: BodyState = m_contact_monitor.body_map.get(id)
	assert(bs)
	assert(bs.in_scene)
	bs.in_scene = false

	m_contact_monitor.locked = true

	body_exited.emit(node)

	for s in bs.shapes:
		body_shape_exited.emit(bs.rid, node, s.x, s.y)

	m_contact_monitor.locked = false

func __body_inout(status: int, body: RID, instance: int, body_shape: int, local_shape: int) -> void: 
	var body_in: bool = status == 1
	var obj_id: int = instance

	var obj: Object = instance_from_id(obj_id)
	var node: Node = obj as Node
	
	assert(m_contact_monitor)
	var bs: BodyState = m_contact_monitor.body_map.get(obj_id)
	assert(bs or body_in)

	if body_in:
		if not bs:
			bs = BodyState.new()
			m_contact_monitor.body_map[obj_id] = bs
			bs.rid = body
			bs.in_scene = node and node.is_inside_tree()
			if node:
				node.tree_entered.connect(__body_enter_tree.bind(obj_id))
				node.tree_exited.connect(__body_exit_tree.bind(obj_id))
				if bs.in_scene:
					body_entered.emit(node)

		if node:
			bs.shapes.push_back(Vector3i(body_shape, local_shape, 0))
		
		if bs.in_scene:
			body_shape_entered.emit(body, node, body_shape, local_shape)
	else:
		if node:
			bs.shapes.erase(Vector3i(body_shape, local_shape, 0))
		
		var in_scene: bool = bs.in_scene

		if bs.shapes.is_empty():
			if node:
				node.tree_entered.disconnect(__body_enter_tree)
				node.tree_exited.disconnect(__body_exit_tree)
				if in_scene:
					body_exited.emit(node)
		
		if node and in_scene:
			body_shape_exited.emit(body, node, body_shape, local_shape)

func __body_state_changed(state: PhysicsDirectBodyState2D, index: int) -> void:
	_lock_callback()

	set_notify_transform(false)

	if not m_freeze or m_freeze_mode != FreezeMode.KINEMATIC:
		set_global_transform_2d(state.transform)
	
	# First thing first, let's convert the state transformations to fit to 3D world
	var itr: Transform2D = itr2d()
	var tr: Transform2D = tr2d()
	state.transform = itr * state.transform
	state.linear_velocity = itr * state.linear_velocity

	m_linear_velocity = state.linear_velocity
	m_angular_velocity = state.angular_velocity

	if m_sleeping != state.sleeping:
		m_sleeping = state.sleeping
		sleeping_state_changed.emit()
	
	_integrate_forces(state)

	# Now, let's convert back
	state.transform = tr * state.transform
	state.linear_velocity = tr * state.linear_velocity

	set_notify_transform(true)

	if m_contact_monitor:
		m_contact_monitor.blocked = true

		var rc: int = 0
		for bs in m_contact_monitor.body_map.values():
			for s in bs.shapes:
				s.tagged = false
				rc += 1
		
		var toadd: Array[RigidBodySpatial2DInOut] = []
		for i in state.get_contact_count():
			toadd.push_back(RigidBodySpatial2DInOut.new())
		var toadd_count: int = 0
		var toremove: Array[RigidBodySpatial2D_RemoveAction] = []
		for i in rc:
			toremove.push_back(RigidBodySpatial2D_RemoveAction.new())
		var toremove_count: int = 0

		for i in state.get_contact_count():
			var col_rid: RID = state.get_contact_collider(i)
			var col_obj: int = state.get_contact_collider_id(i)
			var local_shape: int = state.get_contact_local_shape(i)
			var col_shape: int = state.get_contact_collider_shape(i)

			var b: BodyState = m_contact_monitor.body_map.get(col_obj)
			if not b:
				toadd[toadd_count].rid = col_rid
				toadd[toadd_count].local_shape = local_shape
				toadd[toadd_count].id = col_obj
				toadd[toadd_count].shape = col_shape
				toadd_count += 1
				continue
			
			var sp: Vector3i = Vector3i(col_shape, local_shape, 0)
			var idx: int = b.shapes.find(sp)
			if idx == -1:
				toadd[toadd_count].rid = col_rid
				toadd[toadd_count].local_shape = local_shape
				toadd[toadd_count].id = col_obj
				toadd[toadd_count].shape = col_shape
				toadd_count += 1
				continue
			
			b.shapes[idx].z = 1

		for bsk in m_contact_monitor.body_map.keys():
			var bs: BodyState = m_contact_monitor.body_map[bsk]
			for s in bs.shapes:
				if not s.z:
					toremove[toremove_count].rid = bs.rid
					toremove[toremove_count].body_id = bsk
					toremove[toremove_count].pair = s
					toremove_count += 1

		for i in toremove_count:
			__body_inout(0, toremove[i].rid, toremove[i].body_id, toremove[i].pair.x, toremove[i].pair.y)
		
		for i in toadd_count:
			__body_inout(1, toadd[i].rid, toadd[i].id, toadd[i].shape, toadd[i].local_shape)
		
		m_contact_monitor.locked = false

	_unlock_callback()

# -- Protected functions --
func _init() -> void:
	_new(PhysicsServer2D.BODY_MODE_RIGID)
	PhysicsServer2D.body_set_force_integration_callback(get_rid(), __body_state_changed, 0)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			if Engine.is_editor_hint():
				set_notify_local_transform(true)
		
		NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
			if Engine.is_editor_hint():
				update_configuration_warnings()

		NOTIFICATION_PREDELETE:
			m_contact_monitor = null

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = super._get_configuration_warnings()

	var tr: Transform3D = global_transform

	if abs(tr.basis.x.length() - 1.0) > 0.05 or abs(tr.basis.y.length() - 1.0) > 0.05:
		warnings.push_back("Size changes to RigidBody2D will be overridden by the physics engine when running.\nChange the size in children collision shapes instead.")

	return warnings

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void: pass

func _apply_body_mode() -> void: 
	if m_freeze:
		match m_freeze_mode:
			FreezeMode.STATIC:
				set_body_mode(PhysicsServer2D.BODY_MODE_STATIC)
			FreezeMode.KINEMATIC:
				set_body_mode(PhysicsServer2D.BODY_MODE_KINEMATIC)
	elif m_lock_rotation:
		set_body_mode(PhysicsServer2D.BODY_MODE_RIGID_LINEAR)
	else:
		set_body_mode(PhysicsServer2D.BODY_MODE_RIGID)

# -- Public functions --
func get_contact_count() -> int:
	var bs: PhysicsDirectBodyState2D = PhysicsServer2D.body_get_direct_state(get_rid())
	assert(bs)
	return bs.get_contact_count()

func apply_central_impulse(imp: Vector2) -> void:
	PhysicsServer2D.body_apply_central_impulse(get_rid(), tr2d() * imp)

func apply_impulse(imp: Vector2, pos: Vector2 = Vector2()) -> void:
	PhysicsServer2D.body_apply_impulse(get_rid(), tr2d() * imp, tr2d() * pos)

func apply_torque_impulse(torque: float) -> void: 
	PhysicsServer2D.body_apply_torque(get_rid(), torque)

func apply_central_force(force: Vector2) -> void:
	PhysicsServer2D.body_apply_central_force(get_rid(), tr2d() * force)

func apply_force(force: Vector2, pos: Vector2 = Vector2()) -> void:
	PhysicsServer2D.body_apply_force(get_rid(), tr2d() * force, tr2d() * pos)

func apply_torque_force(torque: float) -> void: 
	PhysicsServer2D.body_apply_torque(get_rid(), torque)

func add_constant_central_force(force: Vector2) -> void:
	PhysicsServer2D.body_add_constant_central_force(get_rid(), tr2d() * force)

func add_constant_force(force: Vector2, pos: Vector2 = Vector2()) -> void:
	PhysicsServer2D.body_add_constant_force(get_rid(), tr2d() * force, tr2d() * pos)

func add_constant_torque_force(torque: float) -> void: 
	PhysicsServer2D.body_add_constant_torque(get_rid(), torque)

func get_colliding_bodies() -> Array[Node]: 
	assert(m_contact_monitor)

	var ret: Array[Node] = []
	ret.resize(m_contact_monitor.body_map.size())
	var idx: int = 0
	for bsk in m_contact_monitor.body_map.keys():
		var bs: BodyState = m_contact_monitor.body_map[bsk]
		var obj: Object = instance_from_id(bsk)
		if not obj:
			ret.resize(ret.size() - 1)
		else:
			ret[idx] = obj as Node
			idx += 1

	return ret




