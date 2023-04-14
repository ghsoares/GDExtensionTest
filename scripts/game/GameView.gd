extends Control
class_name GameView

## The view game
var game: Game

## The game viewport
var viewport: SubViewport

## The game viewport texture
var view_texture: TextureRect

## The game pixel scale
@export var pixel_scale: float = 4.0

## Called when entering the tree
func _enter_tree() -> void:
	# Get nodes
	game = get_parent()
	viewport = $View
	view_texture = $ViewTex

## Called when ready
func _ready() -> void:
	_update_viewport_size()
# 	_update_viewport_transform()

# ## Called every frame
# func _process(delta: float) -> void:
# 	_update_viewport_transform()

## Update the viewport size
func _update_viewport_size() -> void:
	# Get the parent viewport size
	var size: Vector2 = get_viewport().get_visible_rect().size

	# Set the viewport size (add one extra pixel if want smooth camera)
	viewport.size = size / pixel_scale
	viewport.size_2d_override = size
	viewport.size_2d_override_stretch = true

# ## Set the viewport transform
# func _update_viewport_transform() -> void:
# 	# Get the parent viewport size
# 	var size: Vector2 = get_viewport().get_visible_rect().size

# 	# Get pixel size
# 	var pixel_size: Vector2 = size / pixel_scale + Vector2.ONE

# 	# Get the level
# 	var level: Level = game.level

# 	# Set the view texture transform
# 	var tr: Transform2D = Transform2D.IDENTITY

# 	# Get the camera transform
# 	var cam_tr: Transform3D = level.camera.get_camera_transform()

# 	# Get the camera snap
# 	var snap: float = level.camera.pixel_snap

# 	# Get the camera position
# 	var pos: Vector3 = cam_tr.basis.inverse() * cam_tr.origin

# 	# Get the snapping
# 	var px: float = pos.x / snap
# 	var py: float = pos.y / snap
# 	var fx: float = px - floor(px)
# 	var fy: float = py - floor(py)

# 	# Set the scale
# 	tr = Transform2D().translated(
# 		Vector2(0.0, -pixel_scale) + 
# 		Vector2(-fx, fy) * pixel_scale
# 	) * Transform2D().scaled(
# 		Vector2.ONE + (Vector2.ONE / size) * pixel_scale
# 	)
# 	# tr *= Transform2D().translated(
# 	# 	Vector2.ZERO,
# 	# 	# Vector2(-fx, -fy) * pixel_scale
# 	# ) * Transform2D().scaled(
# 	# 	Vector2.ONE + (Vector2.ONE / size) * pixel_scale
# 	# )

# 	# Set the view texture transform
# 	RenderingServer.canvas_item_set_transform(
# 		view_texture.get_canvas_item(), tr
# 	)



