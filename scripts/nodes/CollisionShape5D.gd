extends Node3D
class_name CollisionShape5D

## Parent rigidbody
var parent: RigidBody5D

## Previous shape rid
var shape_rid: RID

## The actual shape
@export var shape: Shape2D:
	set (value):
		if shape != value:
			shape = value
			_update_collision_shape()
	get:
		return shape

## Is disabled or not
@export var disabled: bool:
	set (value):
		if disabled != value:
			disabled = value
			_update_collision_shape()
	get:
		return disabled

## Called when receiving a notification
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			parent = get_parent() as RigidBody5D
			_update_collision_shape()
			set_notify_local_transform(true)
		NOTIFICATION_EXIT_TREE:
			if parent and shape != null:
				parent.remove_collision_shape(shape.get_rid())
			parent = null
		NOTIFICATION_TRANSFORM_CHANGED:
			_update_collision_shape()

## Update parent collision shape
func _update_collision_shape() -> void:
	# Get shape rid
	var rid: RID = RID() if shape == null else shape.get_rid()

	# Only update if has a parent
	if parent:
		# Remove collision shape
		if shape_rid != RID() and rid == RID():
			parent.remove_collision_shape(shape_rid)
		else:
			parent.update_collision_shape(
				rid, Utils.transform_3d_to_2d(transform), disabled
			)




