extends Control
class_name GameUI

## The UI game
var game: Game

## The player position UI node
var player_position: GameUIPlayerPosition

## Called when entering the tree
func _enter_tree() -> void:
	game = get_parent()
	player_position = $PlayerPosition

## Called every frame
func _process(delta: float) -> void:
	# The level
	var level: Level = game.level

	# The player ship
	var ship: Ship = level.ship

	# Get the level viewport
	var view: Viewport = level.get_viewport()

	# Get the level camera
	var cam: Camera3D = level.camera.camera

	# Get the level camera transform
	var cam_tr: Transform3D = cam.get_camera_transform()

	# Get the player position
	var pos: Vector3 = ship.global_transform.origin

	# Get the player rotation
	var rot: Basis = ship.global_transform.basis

	# Get the player position relative to the viewport
	var view_pos: Vector2 = cam.unproject_position(pos)

	# Get the player rotation relative to the viewport
	var view_rot: Basis = cam_tr.basis.inverse() * rot

	# Get the player velocity relative to the viewport
	var view_vel: Vector3 = cam_tr.basis.inverse() * Vector3(ship.linear_velocity.x, ship.linear_velocity.y, 0.0)

	# Get position relative to the viewport
	view_pos /= view.get_visible_rect().size

	# Set the player position variables
	player_position.scl = 1.0 / level.camera.curr_zoom
	player_position.size = max(ship.size.x, ship.size.y) * player_position.scl
	player_position.pos = view_pos * size
	player_position.rot = -view_rot.get_euler().z
	player_position.vel = Vector2(view_vel.x, -view_vel.y)


