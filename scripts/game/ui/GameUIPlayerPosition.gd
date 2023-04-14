@tool
extends Node2D
class_name GameUIPlayerPosition

## RID used for the rotation part
var rot_ui: RID

## RID used for the velocity part
var velocity_ui: RID

# Current player size (relative to UI)
var size: float

# Current player scale
var scl: float = 1.0

# Current player position (relative to UI)
var pos: Vector2 = Vector2(128.0, 128.0)

# Current player rotation (relative to UI)
var rot: float = deg_to_rad(45.0)

# Current player velocity
var vel: Vector2 = Vector2(512.0, 0.0)

## Margin from the ship
@export var ui_margin: float = 16.0

## Velocity ui size
@export var velocity_size: float = 64.0

## Velocity scaling factor
@export var velocity_scale_factor: float = 1.0

## Velocity arrow width
@export var velocity_arrow_width: float = 8.0

## Rotation arrow length
@export var rotation_arrow_length: float = 64.0

## Rotation arrow width
@export var rotation_arrow_width: float = 8.0

## Color of the rotation ui
@export var rotation_color: Color = Color.WHITE

## Color of the velocity ui
@export var velocity_color: Color = Color.WHITE

## Material for the rotation ui
@export var rotation_material: Material:
	get: return rotation_material
	set(value):
		if rotation_material == value: return
		rotation_material = value
		RenderingServer.canvas_item_set_material(
			rot_ui, rotation_material.get_rid() if rotation_material else RID()
		)

## Material for the velocity ui
@export var velocity_material: Material:
	get: return velocity_material
	set(value):
		if velocity_material == value: return
		velocity_material = value
		RenderingServer.canvas_item_set_material(
			rot_ui, velocity_material.get_rid() if velocity_material else RID()
		)

## Called when initialized
func _init() -> void:
	rot_ui = RenderingServer.canvas_item_create()
	velocity_ui = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(rot_ui, get_canvas_item())
	RenderingServer.canvas_item_set_parent(velocity_ui, get_canvas_item())

## Called when receing a notification
func _notification(what: int) -> void:
	# Called when destructured
	if what == NOTIFICATION_PREDELETE:
		RenderingServer.free_rid(rot_ui)
		RenderingServer.free_rid(velocity_ui)

## Called every frame
func _process(delta: float) -> void:
	# Set base transform
	transform.origin = pos

	# Get velocity length
	var vel_len: float = vel.length()

	# Get velocity direction
	var vel_dir: Vector2 = vel / vel_len if vel_len > 0.0 else vel

	# Get velocity scale
	var vel_scl: float = 1.0 - (1.0 / (1.0 + vel_len * velocity_scale_factor))

	# Clear rotation and velocity ui
	RenderingServer.canvas_item_clear(rot_ui)
	RenderingServer.canvas_item_clear(velocity_ui)

	# Draw rotation arrow
	RenderingServer.canvas_item_add_line(
		rot_ui, 
		Vector2(0.0, -size * 0.5 - ui_margin).rotated(rot),
		Vector2(0.0, -size * 0.5 - ui_margin - rotation_arrow_length).rotated(rot),
		rotation_color,
		rotation_arrow_width, true
	)

	# Draw velocity arrow
	RenderingServer.canvas_item_add_line(
		velocity_ui,
		vel_dir * ui_margin,
		vel_dir * (ui_margin + vel_scl * velocity_size),
		velocity_color,
		velocity_arrow_width, true
	)







