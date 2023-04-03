extends Node3D
class_name CollisionShape5D

## Parent rigidbody
var parent: RigidBody5D

## Current shape RID
var shape_rid: RID

## The actual shape
@export var shape: Shape2D:
	set (value):
		if shape != value:
			shape = value
			_set_collision_shape()
	get:
		return shape

## Called when receiving a notification
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			parent = get_parent() as RigidBody5D
			_set_collision_shape()
			set_notify_local_transform(true)
		NOTIFICATION_EXIT_TREE:
			if parent and shape_rid != RID():
				parent.remove_collision_shape(shape_rid)
			parent = null
		NOTIFICATION_TRANSFORM_CHANGED:
			_update_collision_shape()

## Update parent collision shape
func _update_collision_shape() -> void:
	if parent:
		parent.update_collision_shape(
			shape_rid, Utils.transform_3d_to_2d(transform, parent.pixel_size)
		)

## Set the parent collision shape
func _set_collision_shape() -> void:
	# Get shape RID
	shape_rid = shape.get_rid() if shape != null else RID()

	# Set shape in parent
	if parent:
		parent.update_collision_shape(shape_rid, Utils.transform_3d_to_2d(transform, parent.pixel_size))




