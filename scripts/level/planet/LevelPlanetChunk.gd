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
var is_visible: bool

## Current generation task
var task_id: int = -1

## Queried deletion
var deletion_queried: bool = false

## Queried generation
var generation_queried: bool = false

## Finished generation
var generation_finished: bool = false

## Signal emited when this chunk is deleted
signal deleted(lod: int, index: Vector2i)

## Initialize this chunk
func initialize() -> void:
	# Allocate resources
	instance = RenderingServer.instance_create()
	material = material.duplicate()

	# Add instance to world and add geometry
	var scenario = chunk_manager.planet.level.get_world_3d().scenario
	RenderingServer.instance_set_scenario(instance, scenario)
	RenderingServer.instance_set_base(instance, mesh.get_rid())
	RenderingServer.instance_geometry_set_material_override(instance, material.get_rid())

## Update this chunk
func update() -> void:
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
			deletion_queried = false
			_delete()

## Query this chunk to generate
func query_generate() -> void:
	# Already queried to generate
	if generation_queried: return
	
	# Is currently generating
	if task_id != -1: generation_queried = true
	else:
		# Call the task
		task_id = ThreadPool.queue_task(_update_texture)

## Update chunk transform relative to planet transform
func update_transform() -> void:
	# Get chunk position and size
	var size: Vector2 = chunk_manager.get_chunk_size(lod)
	var pos: Vector2 = Vector2(index.x, index.y) * size

	# Set transform
	tr = Transform3D(
		Basis.from_scale(Vector3(size.x, size.y, 1.0)),
		Vector3(pos.x, pos.y, 0.0)
	)
	RenderingServer.instance_set_transform(
		instance, 
		chunk_manager.global_transform * tr
	)
	RenderingServer.material_set_param(material.get_rid(), "transform", tr)

## Set the chunk transparency
func set_transparency(a: float) -> void:
	RenderingServer.material_set_param(material.get_rid(), "transparency", a)

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
	RenderingServer.material_set_param(material.get_rid(), "terrain_size", Vector2(res.x, res.y))

	# Finished generation
	generation_finished = true

## Delete this chunk
func _delete() -> void:
	# Dealocate resources
	RenderingServer.free_rid(tex)
	RenderingServer.free_rid(instance)

	deleted.emit(lod, index)

## Query to delete this chunk
func query_delete() -> void:
	# Already queried to delete
	if deletion_queried: return

	# Is generating
	if task_id != -1:
		deletion_queried = true
	else:
		_delete()
	
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



