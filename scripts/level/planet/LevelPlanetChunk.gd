extends RefCounted
class_name LevelPlanetChunk

## Parent chunk manager
var chunk_manager: LevelPlanetChunkManager

## Chunk index
var index: Vector2i

## Chunk lod
var lod: int

## Chunk quad mesh
var mesh: Mesh

## Chunk material
var material: Material

## Chunk instance
var instance: RID

## Chunk procedural texture
var img: Image
var tex: RID

## Chunk local transform
var tr: Transform3D

## Is visible
var is_visible: bool = true

## Internal fade factor
var _fade: float = 0.0

## Color of the chunk
var color: Color = Color.WHITE

## Current generation task
var task_id: int = -1

## Queried deletion
var deletion_queried: bool = false

## Queried generation
var generation_queried: bool = false

## Finished generation
var generation_finished: bool = false

## Is this chunk alive
var alive: bool = true

## Initialize this chunk
func initialize() -> void:
	# Get chunk position and size
	var size: Vector2 = chunk_manager.get_chunk_size(lod)
	var pos: Vector2 = Vector2(index.x, index.y) * size

	# Allocate resources
	instance = RenderingServer.instance_create()
	material = material.duplicate()

	# Add instance to world and add geometry
	var scenario = chunk_manager.planet.level.get_world_3d().scenario
	RenderingServer.instance_set_scenario(instance, scenario)
	RenderingServer.instance_set_base(instance, mesh.get_rid())
	RenderingServer.instance_geometry_set_material_override(instance, material.get_rid())

	# Set transform
	tr = Transform3D(
		Basis.from_scale(Vector3(size.x, size.y, 1.0)),
		Vector3(pos.x, pos.y, 0.0)
	)

## Update this chunk
func update(delta: float) -> void:
	# Fade-in and fade-out time (in secs)
	var fade_in: float = 0.25
	var fade_out: float = 0.25

	# Show
	if is_visible:
		if _fade < 1.0:
			_fade += min((1 + fade_in) - _fade, delta / fade_in)
		else: _fade = 1.0 + fade_in
	# Hide
	else:
		if _fade > 1.0:
			_fade += max(-_fade, -delta)
		else:
			_fade += max(-_fade, -delta / fade_out)

	# Result fade
	var f: float = clamp(_fade, 0.0, 1.0)
	f = ease(f, -2.0)
	
	# Set material coor
	RenderingServer.material_set_param(
		material.get_rid(), "color", 
		color * Color(1.0, 1.0, 1.0, f)
	)

	# Set visible to false when fade is equal zero
	RenderingServer.instance_set_visible(instance, _fade > 0.0)

	# Check if generation finished
	if task_id != -1 and generation_finished:
		task_id = -1
		generation_finished = false

		# Queried to generate again
		if generation_queried:
			generation_queried = false
			query_generate()
		# Queried to delete
		if deletion_queried:
			_delete()

## Query this chunk to generate
func query_generate() -> void:
	# Already queried to generate
	if generation_queried: return

	# Is queried to delete
	if deletion_queried: return
	
	# Is currently generating
	if task_id != -1: generation_queried = true
	else:
		# Call the task
		task_id = ThreadPool.queue_task(_update_texture)

## Query to delete this chunk
func query_delete() -> void:
	# Already queried to delete
	if deletion_queried: return

	# Is generating
	if task_id != -1:
		deletion_queried = true
	else:
		_delete()

## Update chunk transform relative to planet transform
func update_transform() -> void:
	RenderingServer.instance_set_transform(
		instance, 
		chunk_manager.global_transform * 
		tr * Transform3D().translated(Vector3(0.0, 0.0, color.a - 1.0))
	)
	RenderingServer.material_set_param(material.get_rid(), "transform", tr)

## Generate the terrain texture
func _update_texture() -> void:
	# Get planet
	var planet: LevelPlanet = chunk_manager.planet

	# Get chunk resolution
	var res: Vector2i = chunk_manager.chunk_resolution

	# Get inverse chunk resolution
	var inv_res: Vector2 = Vector2(1.0 / res.x, 1.0 / res.y)

	# Create chunk texture data
	var img_data: PackedByteArray
	img_data.resize((res.x + 3) * (res.y + 3) * 4)

	# Get chunk position and size
	var size: Vector2 = chunk_manager.get_chunk_size(lod)
	var pos: Vector2 = Vector2(index.x, index.y) * size
	var start: Vector2 = pos - size * 0.5
	var start_time: int = Time.get_ticks_msec()

	# For each pixel in resolution
	for iy in res.y + 3:
		for ix in res.x + 3:
			# Get data offset
			var of: int = (iy * (res.x + 3) + ix) * 4

			# Get position
			var pf: Vector2 = Vector2(ix - 1, iy - 1) * inv_res
			var p: Vector2 = start + size * pf

			# Get sdf
			var sdf: float = planet.distance(p.x, p.y)
			
			# Set sdf in image data
			img_data.encode_float(of, sdf)

	# Create image
	if not img:
		img = Image.create_from_data(res.x + 3, res.y + 3, false, Image.FORMAT_RF, img_data)
	else:
		img.set_data(res.x + 3, res.y + 3, false, Image.FORMAT_RF, img_data)

	# Create texture
	if tex == RID():
		tex = RenderingServer.texture_2d_create(img)
	else:
		RenderingServer.texture_2d_update(tex, img, 0)

	# Set texture in material
	RenderingServer.material_set_param(material.get_rid(), "terrain_texture", tex)
	RenderingServer.material_set_param(material.get_rid(), "terrain_resolution", Vector2(res.x, res.y))
	RenderingServer.material_set_param(material.get_rid(), "terrain_size", size * 0.25)

	# Finished generation
	generation_finished = true

## Delete this chunk
func _delete() -> void:
	# Dealocate resources
	RenderingServer.instance_set_scenario(instance, RID())
	RenderingServer.free_rid(tex)
	RenderingServer.free_rid(instance)
	
	instance = RID()
	tex = RID()

	alive = false
	
## Show this chunk
func show() -> void:
	if not is_visible:
		RenderingServer.instance_set_visible(instance, true)
		is_visible = true

## Hide this chunk
func hide() -> void:
	if is_visible:
		RenderingServer.instance_set_visible(instance, false)
		is_visible = false


