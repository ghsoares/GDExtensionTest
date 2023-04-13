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

class ShapePair:
	var body_shape: int
	var local_shape: int
	var tagged: bool

	func lt(other: ShapePair) -> bool:
		if body_shape == other.body_shape:
			return local_shape < other.local_shape
		
		return body_shape < other.body_shape

class RigidBodySpatial2D_RemoveAction:
	var rid: RID
	var body_id: int
	var pair: ShapePair

class BodyState:
	var rid: RID
	var in_scene: bool
	var shapes: Array[ShapePair]

class ContactMonitor:
	var locked: bool = false
	var body_map: Dictionary

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

	assert(m_contact_monitor.body_map.has(id))
	var body: BodyState = m_contact_monitor.body_map[id]
	assert(!body.in_scene)

	m_contact_monitor.locked = true

	body.in_scene = true
	body_entered.emit(node)

	for s in body.shapes:
		body_shape_entered.emit(body.rid, node, s.body_shape, s.local_shape)

	m_contact_monitor.locked = false

func __body_exit_tree(id: int) -> void:
	var obj: Object = instance_from_id(id)
	var node: Node = obj as Node
	assert(node)
	assert(m_contact_monitor)

	assert(m_contact_monitor.body_map.has(id))
	var body: BodyState = m_contact_monitor.body_map[id]
	assert(body.in_scene)
	body.in_scene = false

	m_contact_monitor.locked = true

	body_exited.emit(node)

	for s in body.shapes:
		body_shape_exited.emit(body.rid, node, s.body_shape, s.local_shape)

	m_contact_monitor.locked = false

func __body_inout(status: int, body: RID, instance: int, body_shape: int, local_shape: int) -> void: 
	
	pass

func __body_state_changed(state: PhysicsDirectBodyState2D) -> void: pass

# -- Protected functions --
func _notification(what: int) -> void:
	pass

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	return warnings

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void: pass

func _apply_body_mode() -> void: pass

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




