extends RefCounted
class_name LevelChunk

## Parent terrain
var terrain: LevelTerrain

## Parent chunk manager
var chunk_manager: LevelChunkManager

## Parent level
var level: Level

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

## Is visible
var is_visible: bool

## Initialize this chunk
func initialize() -> void:
	# Allocate resources
	instance = RenderingServer.instance_create()
	material = material.duplicate()

	# Add instance to world and add geometry
	var scenario = level.get_world_3d().scenario
	RenderingServer.instance_set_scenario(instance, scenario)
	RenderingServer.instance_set_base(instance, mesh.get_rid())
	RenderingServer.instance_geometry_set_material_override(instance, material.get_rid())

## Generate this chunk
func generate() -> void:
	# Get chunk position and size
	var size: Vector2 = chunk_manager.get_chunk_size(lod)
	var pos: Vector2 = Vector2(index.x, index.y) * size

	# Check if chunk is inside sdf range
	if terrain.intersects(pos, size):
		_update_texture()

		# Set transform
		var tr: Transform3D = Transform3D(
			Basis.IDENTITY.scaled(Vector3(size.x, size.y, 1.0)),
			Vector3(pos.x, pos.y, 0.0)
		)
		RenderingServer.instance_set_transform(
			instance, 
			chunk_manager.global_transform * tr
		)
	else:
		RenderingServer.instance_set_transform(
			instance, 
			Transform3D().scaled(Vector3.ZERO)
		)

## Generate the terrain texture
func _update_texture() -> void:
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

	# For each pixel in resolution
	for iy in res.y + 3:
		for ix in res.x + 3:
			# Get data offset
			var of: int = (iy * (res.x + 3) + ix) * 4

			# Get position
			var pf: Vector2 = Vector2(ix - 1, iy - 1) * inv_res
			var p: Vector2 = start + size * pf

			# Get sdf
			var sdf: float = terrain.sdf(p.x, p.y)
			
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

## Delete this chunk
func delete() -> void:
	# Dealocate resources
	RenderingServer.free_rid(tex)
	RenderingServer.free_rid(instance)

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



