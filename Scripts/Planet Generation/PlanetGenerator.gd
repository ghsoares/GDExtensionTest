extends Control

class_name PlanetGenerator

signal finished_generation

var windSpeedRange = Vector2(4, 16)

var planet
var terrain
var terrainMaterial: ShaderMaterial
var noise: OpenSimplexNoise
var liquidPlacer: LiquidPlacer
var platformsPlacer: PlatformsPlacer

var yields: int = 0 setget SetYields

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

func PlaceLiquidBodies(liquidMaterial: ShaderMaterial, rate: float = .5, heightRange: Vector2 = Vector2(32.0, 256.0)) -> Array:
	liquidPlacer.rate = rate
	liquidPlacer.material = liquidMaterial
	liquidPlacer.heightRange = heightRange
	return liquidPlacer.Place()

func PrepareGeneration() -> void:
	terrain = Terrain.new()
	liquidPlacer = LiquidPlacer.new()
	terrainMaterial = GameMaterials.GetMaterial("Planets/Default/Terrain")
	noise = OpenSimplexNoise.new()
	platformsPlacer = PlatformsPlacer.new()
	
	noise.period = 256.0

func Generate() -> void:
	PrepareGeneration()
	
	planet.windSpeed = floor(rand_range(windSpeedRange.x, windSpeedRange.y + 1.0)) * sign(randf() * 2.0 - 1.0)
	
	noise.seed = randi()
	
	terrain.size = planet.size
	terrain.noise = noise
	terrain.material = terrainMaterial
	terrain.platformsPlacer = platformsPlacer
	
	liquidPlacer.terrain = terrain
	planet.terrain = terrain
	
	platformsPlacer.size = planet.size
	platformsPlacer.planet = planet
	platformsPlacer.terrain = terrain
	
	MaterialSetNoiseSeed(terrainMaterial, "terrainTexture")
	
	add_child(terrain)
	add_child(platformsPlacer)
	add_child(liquidPlacer)
	
	platformsPlacer.Place()
	terrain.Generate()
	
	if yields == 0:
		emit_signal("finished_generation")



