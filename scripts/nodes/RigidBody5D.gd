extends Node3D
class_name RigidBody5D

## Body RID of this node
var body_rid: RID = RID()

## Shapes of this node
var shapes: Array[RID]

## Pixel size used to convert from 3D to 2D
@export var pixel_size: float = 1.0

## Collision layer of this body
@export_flags_2d_physics var collision_layer: int = 1

## Collision layer mask to check collisions
@export_flags_2d_physics var collision_mask: int = 1

## Called when initialized
func _init() -> void:
	# Create body
	body_rid = PhysicsServer2D.body_create()
	PhysicsServer2D.body_set_force_integration_callback(
		body_rid, self.integrate_forces
	)
	PhysicsServer2D.body_set_param(
		body_rid, PhysicsServer2D.BODY_PARAM_GRAVITY_SCALE, 0.0
	)
	PhysicsServer2D.body_set_param(
		body_rid, PhysicsServer2D.BODY_PARAM_LINEAR_DAMP_MODE, 
		PhysicsServer2D.BODY_DAMP_MODE_REPLACE
	)
	PhysicsServer2D.body_set_param(
		body_rid, PhysicsServer2D.BODY_PARAM_ANGULAR_DAMP_MODE, 
		PhysicsServer2D.BODY_DAMP_MODE_REPLACE
	)
	# PhysicsServer2D.body_set_state(
	# 	body_rid, PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, deg_to_rad(8.0)
	# )
	# PhysicsServer2D.body_set_state(
	# 	body_rid, PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2(0.0, 32.0)
	# )

## Called when receiving a notification
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			PhysicsServer2D.free_rid(body_rid)
		NOTIFICATION_ENTER_TREE:
			# Add body to world
			PhysicsServer2D.body_set_space(
				body_rid, get_world_2d().space
			)
			update_body_transform()
		NOTIFICATION_EXIT_TREE:
			# Remove body from world
			PhysicsServer2D.body_set_space(
				body_rid, get_world_2d().space
			)
		NOTIFICATION_TRANSFORM_CHANGED:
			update_body_transform()

## Integrate forces
func integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	set_notify_transform(false)
	set_transform_2d(state.transform)
	set_notify_transform(true)

## Adds a collision shape
func add_collision_shape(shape: RID, tr: Transform2D) -> void:
	PhysicsServer2D.body_add_shape(
		body_rid, shape, tr
	)
	shapes.append(shape)

## Update collision shape placement
func update_collision_shape(shape: RID, tr: Transform2D) -> void:
	var idx: int = shapes.find(shape)
	if idx == -1:
		PhysicsServer2D.body_add_shape(
			body_rid, shape, tr
		)
		shapes.append(shape)
	else:
		PhysicsServer2D.body_set_shape_transform(
			body_rid, idx, tr
		)

## Removes a collision shape
func remove_collision_shape(shape: RID) -> void:
	var idx: int = shapes.find(shape)
	if idx != -1:
		PhysicsServer2D.body_remove_shape(
			body_rid, idx
		)
		shapes.remove_at(idx)

## Update body transform
func update_body_transform() -> void:
	set_notify_transform(false)
	set_transform_3d(global_transform)
	set_notify_transform(true)

## Gets the global 2D transform
func get_transform_2d() -> Transform2D:
	return Utils.transform_3d_to_2d(global_transform, self.pixel_size)

## Gets the global 3D transform
func get_transform_3d() -> Transform2D:
	return global_transform

## Sets the global 2D transform
func set_transform_2d(transform: Transform2D) -> void:
	# Get transform in 3D and 2D
	var tr_3d: Transform3D = Utils.transform_2d_to_3d(transform, self.pixel_size)
	var tr_2d: Transform2D = transform

	# Get body state
	var state: PhysicsDirectBodyState2D = get_body_state()
	
	# Get current transform 3D and 2D
	var cur_3d: Transform3D = global_transform
	var cur_2d: Transform2D = state.transform

	# Set position
	cur_3d.origin.x = tr_3d.origin.x
	cur_3d.origin.y = tr_3d.origin.y
	cur_3d.basis.x = tr_3d.basis.x
	cur_3d.basis.y = tr_3d.basis.y

	# Set the body transform
	cur_2d = tr_2d

	# Set the transforms
	global_transform = cur_3d
	state.transform = cur_2d

## Sets the global 3D transform
func set_transform_3d(transform: Transform3D) -> void:
	# Get transform in 2D
	var tr: Transform2D = Utils.transform_3d_to_2d(transform, self.pixel_size)

	# Get body state
	var state: PhysicsDirectBodyState2D = get_body_state()

	# Set the body transform
	state.transform = tr

	# Set the node global transform
	global_transform = transform

## Gets world 2D
func get_world_2d() -> World2D:
	return get_viewport().world_2d

## Gets the body state
func get_body_state() -> PhysicsDirectBodyState2D:
	return PhysicsServer2D.body_get_direct_state(body_rid)



