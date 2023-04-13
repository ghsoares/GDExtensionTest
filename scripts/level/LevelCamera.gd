extends Node3D
class_name LevelCamera

## The parent level of this camera
var level: Level

## The actual camera
var camera: Camera3D

## Current viewport size
var view_size: Vector2 = Vector2.ONE

## Linear velocity
var linear_velocity: Vector2

## Current transform
var curr_transform: Transform3D

## Current offset
var curr_offset: Vector2

## Current zoom
var curr_zoom: float

## Target velocity
var target_velocity: Vector2

## Target transform
var target_transform: Transform3D

## Target zoom
var target_zoom: float

## Pixel size
@export var pixel_size: float = 0.01

## Angular interpolation
@export var rotation_lerp: float = 8.0

## Acceleration multiplier
@export var acceleration_mul: float = 1.0

## Offset spring force
@export var spring_force: float = 64.0

## Offset spring drag
@export var spring_drag: float = 8.0

## Zoom interpolation
@export var zoom_lerp: float = 8.0

## Near planet zoom
@export var near_zoom: float = 16.0

## Far planet zoom
@export var far_zoom: float = 128.0

## Near distance
@export var near_distance: float = 256.0

## Far distance
@export var far_distance: float = 512.0

## Called when entering the tree
func _enter_tree() -> void:
	# Get the nodes
	level = get_parent()
	camera = $Pivot/Camera

	# Set current and target variables
	linear_velocity = Vector2.ZERO
	curr_transform = global_transform
	curr_zoom = 4.0
	target_velocity = Vector2.ZERO
	target_transform = curr_transform
	target_zoom = curr_zoom

	# Update the camera
	__update_camera()

## Process every physics frame
func _physics_process(delta: float) -> void:
	# Get ship and it's transform
	var ship: Ship = level.ship
	var ship_tr: Transform3D = ship.global_transform

	# Get current ship velocity
	var vel: Vector2 = ship.get_body_state().linear_velocity
	
	# Get current ship acceleration
	var acc: Vector2 = (vel - target_velocity) / delta
	target_velocity = vel

	# Set target position
	target_transform.origin = ship_tr.origin

	# Get gravity
	var grav: Vector2 = level.terrain.gravity_field(
		curr_transform.origin.x, curr_transform.origin.y
	)

	# Get current distance
	var dst: float = level.terrain.distance(
		curr_transform.origin.x, curr_transform.origin.y
	)

	# Has gravity (min length of 0.1)
	if grav.length_squared() >= 0.1 * 0.1:
		# Get "up" direction
		var up: Vector2 = -grav.normalized()

		# Get "right" direction
		var right: Vector2 = Vector2(up.y, -up.x)

		# Set target orientation
		target_transform.basis.x.x = right.x
		target_transform.basis.x.y = right.y
		target_transform.basis.y.x = up.x
		target_transform.basis.y.y = up.y
	
	# Has a near surface
	if dst != INF:
		# Get desired zoom
		target_zoom = clamp((dst - near_distance) / far_distance, 0.0, 1.0)
		var z1: float = near_zoom
		var z2: float = far_zoom
		target_zoom = z1 + (z2 - z1) * target_zoom
	# Too far away
	else:
		target_zoom = far_zoom

	# Apply velocity
	curr_offset += linear_velocity * delta

	# Add acceleration to velocity
	linear_velocity += -(acc) * acceleration_mul * delta

	# Apply spring
	linear_velocity += -curr_offset * spring_force * delta
	linear_velocity += -linear_velocity * clamp(spring_drag * delta, 0.0, 1.0)

	# Interpolate rotation
	curr_transform.basis = curr_transform.basis.slerp(
		target_transform.basis, clamp(delta * rotation_lerp, 0.0, 1.0)
	)

	# Interpolate zoom
	curr_zoom = lerp(curr_zoom, target_zoom, clamp(delta * zoom_lerp, 0.0, 1.0))
	
	# Set current transform position
	curr_transform.origin = target_transform.origin

	# Get time
	var time: float = Time.get_ticks_msec() / 1000.0

	# curr_zoom = 512.0
	# curr_offset = Vector2.ZERO

	# # Set origin manually
	# curr_zoom = 50.0
	# curr_transform.origin.x = cos(time * TAU / 500.0) * 32.0 * curr_zoom
	# curr_transform.origin.y = -5512.0 + sin(time * TAU / 500.0) * 32.0 * curr_zoom
	# curr_transform.basis = Basis.IDENTITY
	# curr_offset = Vector2.ZERO

## Process every frame
func _process(delta: float) -> void:
	__update_camera()

## Internally update camera
func __update_camera() -> void:
	# Get viewport
	var view: Viewport = get_viewport()

	# Get viewport size
	view_size = view.get_visible_rect().size
	
	# Get aspect size
	var asize: float = view_size.y if camera.keep_aspect == Camera3D.KEEP_HEIGHT else view_size.x

	# Camera transform
	var tr: Transform3D = get_camera_transform()

	# Set camera size and get snap
	camera.size = asize * curr_zoom

	# Get camera snap
	var snap: float = get_camera_snap()

	# # Snap the transform (relative to rotation)
	# tr.origin = tr.basis.inverse() * tr.origin
	# tr.origin.x = floor(tr.origin.x / snap) * snap
	# tr.origin.y = floor(tr.origin.y / snap) * snap
	# tr.origin = tr.basis * tr.origin

	# Set camera transform
	global_transform = tr

## Get camera snap
func get_camera_snap() -> float:
	# Return snap
	return 1.0 * curr_zoom

## Get camera global transform
func get_camera_transform() -> Transform3D:
	# Get transform
	var tr: Transform3D = curr_transform
	tr.origin.x += curr_offset.x * curr_zoom / pixel_size
	tr.origin.y += curr_offset.y * curr_zoom / pixel_size

	return tr

## Get camera global bounds
func get_global_bounds() -> AABB:
	# Get transform
	var tr: Transform3D = get_camera_transform()

	# Get size
	var size: Vector3 = Vector3(
		view_size.x, view_size.y, 0.0
	) * curr_zoom

	# Get local AABB
	var aabb: AABB = AABB(-size * 0.5, size)

	# Return global AABB
	return tr * aabb



