@tool
extends Node3D
class_name CollisionShapeSpatial2D

# -- Private variables --
var m_rect: Rect2 = Rect2(-10, -10, 20, 20)
var m_owner_id: int = 0
var m_parent: CollisionObjectSpatial2D

# -- Public variables --
@export var shape: Shape2D:
	get: return shape
	set(value):
		if shape == value: return
		
		if shape:
			shape.changed.disconnect(__shape_changed)

		shape = value
		update_gizmos()
		
		if m_parent:
			m_parent.shape_owner_clear_shapes(m_owner_id)
			if shape:
				m_parent.shape_owner_add_shape(m_owner_id, shape)
			__update_in_shape_owner()
		
		if shape:
			shape.changed.connect(__shape_changed)
		
		update_configuration_warnings()

@export var disabled: bool = false:
	get: return disabled
	set(value):
		disabled = value
		update_gizmos()
		if m_parent:
			m_parent.shape_owner_set_disabled(m_owner_id, disabled)

@export var one_way_collision: bool = false:
	get: return one_way_collision
	set(value):
		one_way_collision = value
		update_gizmos()
		if m_parent:
			m_parent.shape_owner_set_one_way_collision(m_owner_id, one_way_collision)
		update_configuration_warnings()

@export_range(0, 128, 0.1, "suffix:px") var one_way_collision_margin: float = 1.0:
	get: return one_way_collision_margin
	set(value):
		one_way_collision_margin = value
		if m_parent:
			m_parent.shape_owner_set_one_way_collision_margin(m_owner_id, one_way_collision_margin)

@export var debug_color: Color = Color():
	get: return debug_color
	set(value):
		debug_color = value
		update_gizmos()

# -- Private functions --
func __shape_changed() -> void: 
	update_gizmos()

func __update_in_shape_owner(xform_only: bool = false) -> void:
	m_parent.shape_owner_set_transform(m_owner_id, m_parent.convert_to_2d(transform))
	if xform_only: return
	
	m_parent.shape_owner_set_disabled(m_owner_id, disabled)
	m_parent.shape_owner_set_one_way_collision(m_owner_id, one_way_collision)
	m_parent.shape_owner_set_one_way_collision_margin(m_owner_id, one_way_collision_margin)

func __get_default_debug_color() -> Color: 
	return Color.RED

# -- Protected functions --
func _notification(what: int) -> void: 
	match what:
		NOTIFICATION_PARENTED:
			m_parent = get_parent() as CollisionObjectSpatial2D
			if m_parent:
				m_owner_id = m_parent.create_shape_owner(self)
				if shape:
					m_parent.shape_owner_add_shape(m_owner_id, shape)
				__update_in_shape_owner()
		
		NOTIFICATION_ENTER_TREE:
			if m_parent:
				__update_in_shape_owner()
		
		NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
			if m_parent:
				__update_in_shape_owner(true)
		
		NOTIFICATION_UNPARENTED:
			if m_parent:
				m_parent.remove_shape_owner(m_owner_id)
			m_owner_id = 0
			m_parent = null

func _property_can_revert(property: StringName) -> bool: 
	if property == "debug_color": return true

	return false

func _property_get_revert(property: StringName): 
	if property == "debug_color":
		return __get_default_debug_color()

	return null

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if m_parent == null:
		warnings.push_back("CollisionShape2D only serves to provide a collision shape to a CollisionObject2D derived node. Please only use it as a child of Area2D, StaticBody2D, RigidBody2D, CharacterBody2D, etc. to give them a shape.")
	
	if not shape:
		warnings.push_back("A shape must be provided for CollisionShape2D to function. Please create a shape resource for it!")
	
	# if one_way_collision and m_parent is AreaSpatial2D:
	# 	warnings.push_back("The One Way Collision property will be ignored when the parent is an Area2D.")

	return warnings

