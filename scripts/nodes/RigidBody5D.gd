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
			__sync_body_transform()
		NOTIFICATION_EXIT_TREE:
			# Remove body from world
			PhysicsServer2D.body_set_space(
				body_rid, get_world_2d().space
			)
		NOTIFICATION_TRANSFORM_CHANGED:
			__sync_body_transform()

## Integrate forces
func integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	set_notify_transform(false)
	__sync_node_transform()
	_integrate_forces(state)
	set_notify_transform(true)

## Override this function to customize forces integration
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void: pass

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

## Gets the transform in 2D
func get_transform_2d() -> Transform2D:
	return __body_to_node(get_body_state().transform)

## Sets the transform in 2D
func set_transform_2d(tr: Transform2D) -> void:
	get_body_state().transform = __node_to_body(tr)
	__sync_node_transform()

## Gets world 2D
func get_world_2d() -> World2D:
	return get_viewport().world_2d

## Gets the body state
func get_body_state() -> PhysicsDirectBodyState2D:
	return PhysicsServer2D.body_get_direct_state(body_rid)

## Called to synchronize the body transform to the node transform
func __sync_node_transform() -> void:
	var body: PhysicsDirectBodyState2D = get_body_state()
	var body_tr: Transform2D = body.transform
	var node_tr: Transform2D = __body_to_node(body_tr)
	var tr: Transform3D = global_transform

	tr.origin.x = node_tr.origin.x
	tr.origin.y = node_tr.origin.y
	tr.basis.x.x = node_tr.x.x
	tr.basis.x.y = node_tr.x.y
	tr.basis.y.x = node_tr.y.x
	tr.basis.y.y = node_tr.y.y

	global_transform = tr

## Called to syncrhonize the node transform to the body transform
func __sync_body_transform() -> void:
	var body: PhysicsDirectBodyState2D = get_body_state()
	var tr: Transform3D = global_transform
	var node_tr: Transform2D

	node_tr.origin.x = tr.origin.x
	node_tr.origin.y = tr.origin.y
	node_tr.x.x = tr.basis.x.x
	node_tr.x.y = tr.basis.x.y
	node_tr.y.x = tr.basis.y.x
	node_tr.y.y = tr.basis.y.y

	var body_tr: Transform2D = __node_to_body(node_tr)

	body.transform = body_tr

## Util function to convert from body space to node space
func __body_to_node(tr: Transform2D) -> Transform2D:
	var bx: Vector2 = tr.x
	var by: Vector2 = tr.y
	var o:  Vector2 = tr.origin
	return Transform2D(
		Vector2(
			bx.x * pixel_size, 
			bx.y * pixel_size
		),
		Vector2(
			by.x, 
			by.y
		),
		Vector2(
			o.x * pixel_size, 
			o.y * pixel_size
		)
	)

## Util function to convert from node space to body space
func __node_to_body(tr: Transform2D) -> Transform2D:
	var bx: Vector2 = tr.x
	var by: Vector2 = tr.y
	var o:  Vector2 = tr.origin
	return Transform2D(
		Vector2(
			bx.x / pixel_size, 
			bx.y / pixel_size
		),
		Vector2(
			by.x, 
			by.y
		),
		Vector2(
			o.x / pixel_size, 
			o.y / pixel_size,
		)
	)

