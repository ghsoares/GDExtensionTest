@tool
extends PhysicsBodySpatial2D
class_name RigidBodySpatial2D

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
var m_contact_monitor: ContactMonitor = null

# -- Public variables --
@export var mass: float = 1.0
@export var inertia: float = 0.0
@export var center_of_mass_mode: CenterOfMassMode = CenterOfMassMode.AUTO
@export var physics_material_override: PhysicsMaterial
@export var gravity_scale: float = 1.0
@export var custom_integrator: bool = false
@export var continuous_cd: CCDMode = CCDMode.DISABLED
@export var max_contacts_reported: int = 0
@export var contact_monitor: bool = false
@export var sleeping: bool = false
@export var can_sleep: bool = false
@export var lock_rotation: bool = false
@export var freeze: bool = false 
@export var freeze_mode: FreezeMode = FreezeMode.STATIC

@export_group("Linear", "linear_")
@export var linear_velocity: Vector2 = Vector2.ZERO
@export var linear_damp_mode: DampMode = DampMode.COMBINE
@export var linear_damp: float = 0.0

@export_group("Angular", "angular_")
@export var angular_velocity: float = 0.0
@export var angular_damp_mode: DampMode = DampMode.COMBINE
@export var angular_damp: float = 0.0

@export_group("Constant Forces", "constant_")
@export var constant_force: Vector2 = Vector2.ZERO
@export var constant_torque: float = 0.0

# -- Signals --
signal body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int)
signal body_shape_exited(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int)
signal body_entered(body: Node)
signal body_exited(body: Node)
signal sleeping_state_changed()

# -- Private functions --
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
	
	assert(contact_monitor)
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

func __body_state_changed(state: PhysicsDirectBodyState2D) -> void:
	_lock_callback()

	set_notify_transform(false)

	if not freeze or freeze_mode != FreezeMode.KINEMATIC:
		set_global_transform_2d(state.transform)
	
	linear_velocity = state.linear_velocity
	angular_velocity = state.angular_velocity

	if sleeping != state.sleeping:
		sleeping = state.sleeping
		sleeping_state_changed.emit()
	
	_integrate_forces(state)

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
func _notification(what: int) -> void:
	pass

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	return warnings

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void: pass

func _apply_body_mode() -> void: 
	if freeze:
		match freeze_mode:
			FreezeMode.STATIC:
				set_body_mode(PhysicsServer2D.BODY_MODE_STATIC)
			FreezeMode.KINEMATIC:
				set_body_mode(PhysicsServer2D.BODY_MODE_KINEMATIC)
	pass

# -- Public functions --
func get_contact_count() -> int: return 0

func apply_central_impulse(imp: Vector2) -> void: pass

func apply_impulse(imp: Vector2, pos: Vector2 = Vector2()) -> void: pass

func apply_torque_impulse(torque: float) -> void: pass

func apply_central_force(force: Vector2) -> void: pass

func apply_force(force: Vector2, pos: Vector2 = Vector2()) -> void: pass

func apply_torque(torque: float) -> void: pass

func apply_constant_central_force(force: Vector2) -> void: pass

func apply_constant_force(force: Vector2, pos: Vector2 = Vector2()) -> void: pass

func apply_constant_torque(torque: float) -> void: pass

func get_colliding_bodies() -> Array[Node]: return []




