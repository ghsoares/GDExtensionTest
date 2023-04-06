extends Camera3D
class_name LevelCamera

## The parent level of this camera
var level: Level

## Current zoom level
var zoom: float = 20.0

## Current viewport size
var view_size: Vector2 = Vector2.ONE

## Pixel size
@export var pixel_size: float = 0.01

## Target node
@export var target: Node3D

## Called when entering the tree
func _enter_tree() -> void:
	# Get the nodes
	level = get_parent()

## On ready
func _ready() -> void:
	# Get viewport size
	view_size = get_viewport().get_visible_rect().size

## Process every frame
func _process(delta: float) -> void:
	# var t := Time.get_ticks_msec() / 1000.0
	# t = sin(t * TAU / 30.0) * 0.5 + 0.5
	# zoom = pow(2.0, lerp(0.25, 8.0, t))

	# Get viewport size
	view_size = get_viewport().get_visible_rect().size

	# # Move input
	# var move := Input.get_vector(
	# 	"debug_camera_left", "debug_camera_right",
	# 	"debug_camera_down", "debug_camera_up"
	# ).limit_length(1.0)

	# # Move camera
	# global_transform.origin += Vector3(
	# 	move.x, move.y, 0.0
	# ) * 8.0 * zoom * delta

	# Get target transform
	var target_tr: Transform3D = global_transform
	if target:
		target_tr = target.global_transform
	
	# Get gravity
	var grav: Vector2 = level.terrain.gravity_field(target_tr.origin.x, target_tr.origin.y, 10.0)
	
	# Move camera position
	global_transform.origin.x = target_tr.origin.x
	global_transform.origin.y = target_tr.origin.y

	# Has gravity
	if grav.length_squared() >= 0.1:
		# Get "up" direction
		var up: Vector2 = -grav.normalized()

		# Get tangent
		var tg: Vector2 = Vector2(up.y, -up.x)

		# Set global transform orientation
		var br: Vector3 = global_transform.basis.x
		var bu: Vector3 = global_transform.basis.y
		br.x = tg.x
		br.y = tg.y
		bu.x = up.x
		bu.y = up.y
		global_transform.basis.x = br
		global_transform.basis.y = bu

	# Set camera size
	if keep_aspect == KEEP_HEIGHT:
		size = view_size.y * zoom * pixel_size
	else:
		size = view_size.x * zoom * pixel_size

## Get camera global bounds
func get_global_bounds() -> AABB:
	# Get transform
	var tr: Transform3D = global_transform

	# Get size
	var size: Vector3 = Vector3(
		view_size.x, view_size.y, 0.0
	) * zoom * pixel_size

	# Get local AABB
	var aabb: AABB = AABB(-size * 0.5, size)

	# Return global AABB
	return tr * aabb



