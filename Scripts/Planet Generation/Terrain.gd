extends ColorRect

class_name Terrain

const MAX_RAY_STEPS = 100
const RAY_SURFACE_DIST = .1

var platformsPlacer

var valleys = []
var mountains = []

var size: Vector2
var noise: OpenSimplexNoise
var heightOffset: float = 200.0
var height: float = 300.0
var resolution: float = 1.0/4.0
var platformHeightInterpolationSize := 32.0
var platformHeightInterpolationCurve := -2.0

var heightmapTexture: ImageTexture

func GetNoiseHeight(x: float) -> float:
	var h = (noise.get_noise_1d(x) * .5 + .5) * height + heightOffset
	return h

func GetTerrainHeight(x: float) -> float:
	var h = GetNoiseHeight(x)
	
	for platform in platformsPlacer.platforms:
		var dist = platform.GetDistance(x)
		if dist <= platformHeightInterpolationSize:
			var t = 1.0 - dist / platformHeightInterpolationSize
			t = ease(t, platformHeightInterpolationCurve)
			
			var platH = GetNoiseHeight(platform.position.x)
			platH = floor(platH)
			
			h = lerp(h, platH, t)
	
	return clamp(h, 0.0, size.y)

func GetTerrainY(x: float) -> float:
	return size.y - GetTerrainHeight(x)

func RayIntersect(from: Vector2, direction: Vector2, maxDistance: float = -1, checkInside: bool = false):
	var dO = 0.0
	var dir = 1
	if checkInside:
		dir = -1
	for i in range(MAX_RAY_STEPS):
		var p = from + direction * dO
		
		var tY = GetTerrainY(p.x)
		var diff = tY - p.y
		if abs(diff) > RAY_SURFACE_DIST:
			dO += diff * dir
		else:
			return {
				"point": p,
				"distance": dO
			}
			break
	return null

#This function generates a ImageTexture that can be passed to the material to render the terrain
func GenerateHeightMap() -> void:
	var imageWidth := int(floor(size.x * resolution))
	var image := Image.new()
	image.create(imageWidth, 1, false, Image.FORMAT_RF)
	
	image.lock()
	
	for x in range(imageWidth):
		var height = GetTerrainHeight(x / resolution) / size.y
		image.set_pixel(x, 0, Color(height, 0.0, 0.0))
	
	image.unlock()
	
	heightmapTexture = ImageTexture.new()
	heightmapTexture.create_from_image(image, 0)

#This function uses a simple method to get all peaks and valleys.
#It passes to each terrain height along the size, sees if the height is increasing or decreasing.
#To each increasing/decresing change, it adds a block that can be merged with another blocks to form
#the valleys and peaks
func GetValleyAndMountains() -> void:
	var spacing := 1.0/resolution
	var prevH := GetTerrainHeight(0.0)
	var dir: int = sign(GetTerrainHeight(spacing) - prevH)
	var startDir: int = dir
	
	var regionStart := 0.0
	var minRegionHeight := prevH
	var maxRegionHeight := prevH
	
	var blocks := []
	
	var x = spacing
	while x < size.x:
		var h = GetTerrainHeight(x)
		var thisDir = sign(h - prevH)
		
		maxRegionHeight = max(maxRegionHeight, h)
		minRegionHeight = min(minRegionHeight, h)
		
		if thisDir != dir and thisDir != 0:
			blocks.append(Rect2(
				regionStart, size.y - maxRegionHeight,
				(x - regionStart), maxRegionHeight - minRegionHeight
			))
			
			regionStart = x
			minRegionHeight = h
			maxRegionHeight = h
			dir = thisDir
		
		prevH = h
		x += spacing
	
	blocks.append(Rect2(
		regionStart, size.y - maxRegionHeight,
		(x - regionStart), maxRegionHeight - minRegionHeight
	))
	
	valleys = []
	mountains = []
	
	dir = startDir
	
	for i in range(blocks.size() - 1):
		var block1 = blocks[i]
		var block2 = blocks[i+1]
		if dir == 1:
			var startY = min(block1.position.y, block2.position.y)
			var endY = max(block1.end.y, block2.end.y)
			mountains.append(Rect2(
				block1.position.x, startY,
				block2.end.x - block1.position.x,
				endY - startY
			))
		else:
			var startY = max(block1.position.y, block2.position.y)
			var endY = max(block1.end.y, block2.end.y) + 1
			valleys.append(Rect2(
				block1.position.x, startY,
				block2.end.x - block1.position.x,
				endY - startY
			))
		dir = -dir

func PlaceExtraMaterial(material: ShaderMaterial, z_index: int = 0) -> ColorRect:
	var c: ColorRect = ColorRect.new()
	var n: Node2D = Node2D.new()
	
	c.rect_size = size
	c.material = material.duplicate()
	
	c.material.set_shader_param("terrainHeightMap", heightmapTexture)
	c.material.set_shader_param("terrainSize", size)
	c.material.set_shader_param("terrainResolution", resolution)
	
	add_child(n)
	n.add_child(c)
	
	n.z_index = z_index
	
	return c

func Generate() -> void:
	rect_size = size
	
	GenerateHeightMap()
	GetValleyAndMountains()
	
	material.set_shader_param("terrainHeightMap", heightmapTexture)
	material.set_shader_param("terrainSize", size)
	material.set_shader_param("terrainResolution", resolution)








