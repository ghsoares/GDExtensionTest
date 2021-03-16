tool
extends ColorRect

class_name Terrain

var world
var terrainMaterial
var planetSettings
var heightMap
var collisionMap

export (float) var platformInterpolationSize = 64.0
export (Curve) var platformInterpolationCurve
export (float) var detectionResolution = 1.0/4.0

export (Vector2) var size := Vector2(1024, 600)

const COLLISION_RESOLUTION := .25

func _ready():
	GetResources()

func _process(delta: float) -> void:
	rect_size = size

func GetResources() -> void:
	pass

func SampleHeight(var x) -> float:
	var h = (planetSettings.heightMapNoise.get_noise_1d(x) + 1) / 2.0
	
	h *= planetSettings.terrainHeight
	h += planetSettings.terrainHeightOffset
	h = clamp(h, 1, size.y)
	
	return h
 
func SampleTerrainHeight(var x) -> float:
	var h = SampleHeight(x)
	
	for platform in world.platformPlacer.platforms:
		var dist = platform.DistX(x)
		if dist <= platformInterpolationSize:
			var platPos = platform.position.x
			var halfPlatSize = platform.size / 2.0
			var h0 = SampleHeight(platPos)
			var h1 = SampleHeight(platPos - halfPlatSize)
			var h2 = SampleHeight(platPos + halfPlatSize)
			var platH = (h0 + h1 + h2) / 3.0
			var t = 1.0 - dist / platformInterpolationSize
			platH = ceil(platH)
			
			h = lerp(h, platH, platformInterpolationCurve.interpolate(t))
	
	return h

func SampleCollisionHeight(var x):
	var i = int(floor(x * COLLISION_RESOLUTION))
	
	var x1 = i / COLLISION_RESOLUTION
	var x2 = x1 + 1.0 / COLLISION_RESOLUTION
	var t = (x - x1) / (x2 - x1)
	
	return lerp(collisionMap[i], collisionMap[i+1], t)

func GetBoundaries(var fromX, var toX) -> Rect2:
	var minHeight = size.y
	var maxHeight = 0.0
	var spacing = 1.0 / planetSettings.terrainResolution
	
	for x in range(fromX, toX, spacing):
		var h = SampleTerrainHeight(x)
		
		if h > maxHeight: maxHeight = h
		if h < minHeight: minHeight = h
	
	var bounds = Rect2()
	
	bounds.position.x = fromX
	bounds.size.x = (toX - fromX)
	bounds.position.y = size.y - maxHeight
	bounds.size.y = (maxHeight - minHeight)
	
	return bounds

func SampleNormal(var x) -> Vector2:
	var spacing = .1
	var tang = (SampleCollisionHeight(x) - SampleCollisionHeight(x + spacing)) / spacing
	var n = Vector2(tang, -1.0).normalized()
	return n

func GenerateHeightMap() -> void:
	heightMap = ImageTexture.new()
	var terrainWidth = floor(size.x * planetSettings.terrainResolution)
	var heightMapImg = Image.new()
	heightMapImg.create(terrainWidth, 1, false, Image.FORMAT_RF)
	heightMapImg.lock()
	for i in range(terrainWidth):
		var x = i / planetSettings.terrainResolution
		var h = SampleTerrainHeight(x)
		var hFloat = h / size.y
		heightMapImg.set_pixel(i, 0, Color(hFloat, 0, 0))
	heightMapImg.unlock()
	heightMap.create_from_image(heightMapImg, 0)

func GenerateCollisionMap() -> void:
	collisionMap = []
	var terrainWidth = floor(size.x * COLLISION_RESOLUTION)
	for i in range(terrainWidth):
		var x = i / COLLISION_RESOLUTION
		var h = SampleTerrainHeight(x)
		collisionMap.append(h)

func ApplyMaterial() -> void:
	terrainMaterial = planetSettings.baseMaterial
	material = terrainMaterial
	
	terrainMaterial.set_shader_param("heightMap", heightMap);
	terrainMaterial.set_shader_param("resolution", planetSettings.terrainResolution);
	terrainMaterial.set_shader_param("size", size);

	terrainMaterial.set_shader_param("text", planetSettings.terrainTexture);
	terrainMaterial.set_shader_param("gradient", planetSettings.terrainGradient);
	terrainMaterial.set_shader_param("textureEasing", planetSettings.terrainTextureEasing);
	terrainMaterial.set_shader_param("textureTiling", planetSettings.terrainTextureTiling);
	terrainMaterial.set_shader_param("warpTiling", planetSettings.terrainWarpTiling);
	terrainMaterial.set_shader_param("warpAmount", planetSettings.terrainWarpAmount);
	terrainMaterial.set_shader_param("textureSteps", planetSettings.terrainTextureSteps);
	terrainMaterial.set_shader_param("fadeRange", planetSettings.terrainFadeRange);
	terrainMaterial.set_shader_param("fadeValues", planetSettings.terrainFadeValues);

func ApplyExtraMaterials() -> void:
	for i in range(planetSettings.terrainExtraMaterials.size()):
		var extraMaterial = planetSettings.terrainExtraMaterials[i]
		
		if extraMaterial == null: continue
		
		var zIndex = extraMaterial.render_priority
		
		var layer : ColorRect = ColorRect.new()
		var layerHolder : Node2D = Node2D.new()
		
		extraMaterial.set_shader_param("heightMap", heightMap)
		extraMaterial.set_shader_param("resolution", planetSettings.terrainResolution)
		extraMaterial.set_shader_param("size", size)
		extraMaterial.set_shader_param("text", planetSettings.terrainTexture)
		extraMaterial.set_shader_param("terrainGradient", planetSettings.terrainGradient)
		
		add_child(layerHolder)
		layerHolder.add_child(layer)
		
		layerHolder.z_index = zIndex
		
		layerHolder.position = Vector2.ZERO
		layer.rect_position = Vector2.ZERO
		layer.rect_size = rect_size
		layer.material = extraMaterial

func Generate() -> void:
	rect_position = Vector2.ZERO
	rect_size = size
	
	if planetSettings:
		GenerateCollisionMap()
		
		GenerateHeightMap()
		ApplyMaterial()
		
		if planetSettings.terrainExtraMaterials:
			ApplyExtraMaterials();





