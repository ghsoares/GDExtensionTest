@tool
extends PhysicsBodySpatial2D
class_name StaticBodySpatial2D

# -- Public variables --
@export var physics_material_override: PhysicsMaterial:
	get: return physics_material_override
	set(value):
		if physics_material_override:
			if physics_material_override.changed.is_connected(__reload_physics_characteristics):
				physics_material_override.changed.disconnect(__reload_physics_characteristics)
		
		physics_material_override = value

		if physics_material_override:
			physics_material_override.changed.connect(__reload_physics_characteristics)
		
		__reload_physics_characteristics

@export var constant_linear_velocity: Vector2 = Vector2.ZERO:
	get: return constant_linear_velocity
	set(value):
		constant_linear_velocity = value

		PhysicsServer2D.body_set_state(m_rid, PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, constant_linear_velocity)

@export var constant_angular_velocity: float = 0.0:
	get: return constant_angular_velocity
	set(value):
		constant_angular_velocity = value

		PhysicsServer2D.body_set_state(m_rid, PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, constant_linear_velocity)

# -- Private functions --
func __reload_physics_characteristics() -> void:
	if physics_material_override:
		PhysicsServer2D.body_set_param(m_rid, PhysicsServer2D.BODY_PARAM_BOUNCE, physics_material_override.bounce)
		PhysicsServer2D.body_set_param(m_rid, PhysicsServer2D.BODY_PARAM_FRICTION, physics_material_override.friction)
	else:
		PhysicsServer2D.body_set_param(m_rid, PhysicsServer2D.BODY_PARAM_BOUNCE, 0)
		PhysicsServer2D.body_set_param(m_rid, PhysicsServer2D.BODY_PARAM_FRICTION, 1)

# -- Protected functions --
func _init() -> void:
	_new(PhysicsServer2D.BODY_MODE_STATIC)






