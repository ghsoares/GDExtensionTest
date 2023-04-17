extends Node3D
class_name LevelPlanetChunkManager

## The parent planet of this manager
var planet: LevelPlanet

## Current spawned chunks
var chunks: Dictionary = {}

## Chunk size in pixels
@export var chunk_size: float = 1024.0

## Chunk resolution (used for the SDF map)
@export var chunk_resolution: Vector2i = Vector2i(8, 8)

## Chunk margin (chunks generated outside the view)
@export var chunk_margin: int = 1

## Chunk remove margin (how many chunks outside the view to be removed)
@export var chunk_remove_margin: int = 3

## Lod remove margin (how many LOD levels to a entire level to be removed)
@export var lod_remove_margin: int = 2

## Chunk mesh (simple geometry of the chunk)
@export var chunk_mesh: Mesh

## Chunk material (visual of the chunk)
@export var chunk_material: Material

var first: bool = true

## Called when entering the tree
func _enter_tree() -> void:
	# Get the nodes
	planet = get_parent()

## Called when exiting the tree
func _exit_tree() -> void:
	# Delete all chunks
	for level in chunks.values():
		for chunk in level.values():
			chunk.query_delete()

## Process every frame
func _process(delta: float) -> void:
	# if first: 
	# 	first = false
	# 	return
	# first = false

	# Get camera
	var cam: LevelCamera = planet.level.camera

	# Get planet transform
	var tr: Transform2D = planet.get_transform_2d()

	# Get global bounds
	var b: AABB = cam.get_global_bounds()
	var bounds: Rect2 = Rect2(
		b.position.x, b.position.y,
		b.size.x, b.size.y
	)
	bounds = tr.affine_inverse() * bounds

	# Get min/max camera bounds
	var min_pos: Vector2 = Vector2(bounds.position.x, bounds.position.y)
	var max_pos: Vector2 = Vector2(bounds.end.x, bounds.end.y)

	# Get current lod
	var lodf: float = log(cam.curr_zoom) / log(2.0)
	var lod: int = floor(lodf)
	lodf -= lod

	generate_chunks_inside_bounds(min_pos, max_pos, lod)
	remove_chunks_outside_bounds(min_pos, max_pos, lod)
	update_all_chunks(delta, min_pos, max_pos, lod, lodf)
	
## Generate chunks inside bounds with lod
func generate_chunks_inside_bounds(min_pos: Vector2, max_pos: Vector2, lod: int) -> void:
	# Process one higher
	for i in 1:
		# Get min/max chunk
		var chunk_indexes: Rect2i = get_min_max_chunk(min_pos, max_pos, lod + i)
		var min_chunk: Vector2i = chunk_indexes.position
		var max_chunk: Vector2i = chunk_indexes.size

		# For each chunk inside camera
		for iy in range(min_chunk.y, max_chunk.y + 1):
			for ix in range(min_chunk.x, max_chunk.x + 1):
				# Process this chunk
				generate_chunk_if_not_exists(ix, iy, lod + i)

## Remove chunks outside bounds range
func remove_chunks_outside_bounds(min_pos: Vector2, max_pos: Vector2, lod: int) -> void:
	# Get lod keys
	var lod_keys: Array = chunks.keys()

	# For each lod
	for l in lod_keys:
		# Get min/max chunk
		var chunk_indexes: Rect2i = get_min_max_chunk(min_pos, max_pos, l)
		var min_chunk: Vector2i = chunk_indexes.position
		var max_chunk: Vector2i = chunk_indexes.size

		# Get level chunks
		var level: Dictionary = self.chunks[l]

		# Get lod difference
		var lod_dif: float = l - lod

		# Get chunk keys
		var chunk_keys: Array = level.keys()

		# Remove entire level
		if lod_dif < -lod_remove_margin or lod_dif > lod_remove_margin + 1:
			# For each index
			for index in chunk_keys:
				# Get chunk
				var chunk: LevelPlanetChunk = level[index]

				# Already queried for deletion
				if chunk.deletion_queried: continue

				# Query for deletion
				chunk.query_delete()

				# Instant deletion
				if not chunk.alive: level.erase(index)
		else:
			# For each index
			for index in chunk_keys:
				# Get chunk
				var chunk: LevelPlanetChunk = level[index]

				# Is already queried for deletion
				if chunk.deletion_queried: continue

				# Chunk is too far away
				if index.x < min_chunk.x - chunk_remove_margin or index.x > max_chunk.x + chunk_remove_margin or index.y < min_chunk.y - chunk_remove_margin or index.y > max_chunk.y + chunk_remove_margin:
					chunk.query_delete()

					# Instant deletion
					if not chunk.alive: level.erase(index)				

## Update all chunks with lod and eliminate those outside bounds range
func update_all_chunks(delta: float, min_pos: Vector2, max_pos: Vector2, lod: int, lodf: float) -> void:
	# Get lod keys
	var lod_keys: Array = chunks.keys()

	# For each lod
	for l in lod_keys:
		# Get lod level chunks
		var level: Dictionary = chunks[l]

		# Get lod difference
		var lod_dif: float = l - lod

		# Get chunk keys
		var chunk_keys: Array = level.keys()

		# For each index
		for index in chunk_keys:
			# Get chunk
			var chunk: LevelPlanetChunk = level[index]

			# Set chunk visibilty
			chunk.is_visible = lod_dif == 0

			# Update chunk
			chunk.update(delta)

			# Is not alive anymore
			if not chunk.alive:
				assert(level.erase(index), "Couldn't erase the chunk")
				assert(not level.has(index), "Bugggg")
			else:
				# Update transform
				chunk.update_transform()

## Re-generate all chunks inside bounds range
func regenerate_chunks_inside_bounds(min_pos: Vector2, max_pos: Vector2) -> void:
	# Get lod keys
	var lod_keys: Array = chunks.keys()

	# For each lod
	for l in lod_keys:
		# Get min/max chunk
		var chunk_indexes: Rect2i = get_min_max_chunk(min_pos, max_pos, l)
		var min_chunk: Vector2i = chunk_indexes.position
		var max_chunk: Vector2i = chunk_indexes.size

		# Get chunks
		var chunks: Dictionary = self.chunks[l]

		# Get chunk keys
		var chunk_keys: Array = chunks.keys()

		# For each index
		for index in chunk_keys:
			# Get chunk
			var chunk: LevelPlanetChunk = chunks[index]

			# Is inside range
			if not (index.x < min_chunk.x or index.x > max_chunk.x or index.y < min_chunk.y or index.y > max_chunk.y):
				# Re-generate the chunk
				chunk.generate()

## Get min/max chunk indexes in position range and lod
func get_min_max_chunk(min_pos: Vector2, max_pos: Vector2, lod: int) -> Rect2i:
	# Get chunk size
	var chunk_size = get_chunk_size(lod)

	# Get min/max chunk index
	var min_chunk: Vector2i = ((min_pos + chunk_size * 0.5) / chunk_size).floor()
	var max_chunk: Vector2i = ((max_pos + chunk_size * 0.5) / chunk_size).ceil()
	min_chunk -= Vector2i.ONE * chunk_margin
	max_chunk += Vector2i.ONE * chunk_margin

	# Return min/max chunk indexes as Rect2i
	return Rect2i(min_chunk, max_chunk)

## Get chunk size at lod
func get_chunk_size(lod: int) -> Vector2:
	return Vector2.ONE * chunk_size * pow(2, lod)

## Generate chunk at lod and index if doesn't exist already
func generate_chunk_if_not_exists(x: int, y: int, lod: int) -> void:
	# Get chunk position and size
	var size: Vector2 = get_chunk_size(lod)
	var pos: Vector2 = Vector2(x, y) * size

	# Check if chunk rect is inside planet bounds
	if not planet.intersects(pos - size * 0.5, size): return

	# Get chunks of lod
	var _chunks = self.chunks.get(lod, null)
	if _chunks == null:
		_chunks = {}
		self.chunks[lod] = _chunks
	var chunks: Dictionary = _chunks
	
	# Get chunk index
	var index: Vector2i = Vector2i(x, y)

	# Get chunk
	var chunk: LevelPlanetChunk = chunks.get(index, null)
	if chunk == null:
		# Create new chunk
		chunk = LevelPlanetChunk.new()
		chunks[index] = chunk

		# Set chunk variables
		chunk.chunk_manager = self
		chunk.index = index
		chunk.lod = lod
		chunk.mesh = chunk_mesh
		chunk.material = chunk_material

		# Initialize the chunk
		chunk.initialize()

		# Generate the chunk
		chunk.query_generate()

		# Set the chunk transform
		chunk.update_transform()
