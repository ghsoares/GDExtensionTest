extends Control

class_name PlanetGenerator

signal finished_generation

var windSpeedRange = Vector2(4, 32)

var planet
var terrainMaterial: ShaderMaterial
var noise: OpenSimplexNoise
var liquidPlacer

var yields: int = 0 setget SetYields

func _ready() -> void:
	terrainMaterial = GameMaterials.GetMaterial("Default/Terrain")
	noise = OpenSimplexNoise.new()
	noise.period = 256.0

func SetYields(newYields: int) -> void:
	if yields != newYields:
		yields = newYields
		if yields == 0:
			emit_signal("finished_generation")

func MaterialSetNoiseSeed(material: ShaderMaterial, texName: String) -> void:
	var noiseTex = material.get_shader_param(texName) as NoiseTexture
	if !noiseTex: return
	noiseTex.noise.seed = randi()
	self.yields += 1
	yield(noiseTex, "changed")
	self.yields -= 1

func ApplyWindToMaterial(material: ShaderMaterial) -> void:
	material.set_shader_param("windSpeed", planet.windSpeed)

func PlaceLiquidBodies(liquidMaterial: ShaderMaterial, rate: float = .5, heightRange: Vector2 = Vector2(8.0, 256.0)) -> void:
	if liquidPlacer:
		liquidPlacer.queue_free()
	liquidPlacer = LiquidPlacer.new()
	
	liquidPlacer.rate = rate
	liquidPlacer.material = liquidMaterial
	liquidPlacer.terrain = planet.terrain
	liquidPlacer.heightRange = heightRange
	
	add_child(liquidPlacer)
	liquidPlacer.Place()

func Generate() -> void:
	planet.windSpeed = rand_range(windSpeedRange.x, windSpeedRange.y) * sign(randf() * 2.0 - 1.0)
	
	var terrain = Terrain.new()
	var platformsPlacer = PlatformsPlacer.new()
	
	noise.seed = randi()
	
	terrain.size = planet.size
	terrain.noise = noise
	terrain.material = terrainMaterial
	terrain.platformsPlacer = platformsPlacer
	
	platformsPlacer.size = planet.size
	platformsPlacer.terrain = terrain
	
	planet.terrain = terrain
	
	MaterialSetNoiseSeed(terrainMaterial, "terrainTexture")
	
	add_child(terrain)
	add_child(platformsPlacer)
	
	platformsPlacer.Place()
	terrain.Generate()
	
	if yields == 0:
		emit_signal("finished_generation")



