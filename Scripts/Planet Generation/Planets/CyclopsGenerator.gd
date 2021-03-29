extends PlanetGenerator

var terrainDustScene : PackedScene
var giantWormScene : PackedScene

func PrepareGeneration() -> void:
	.PrepareGeneration()
	terrainMaterial = GameMaterials.GetMaterial("Planets/Cyclops/Terrain")
	terrain.height = 100.0
	terrainDustScene = preload("res://Scenes/ParticleSystems/TerrainDust.tscn")
	giantWormScene = preload("res://Scenes/GiantWorm.tscn")

func Generate() -> void:
	.Generate()
	
	planet.gravity = Vector2.DOWN * 80.0
	
	var fogMaterial = GameMaterials.GetMaterial("Planets/Cyclops/Fog")
	var giantWorm = giantWormScene.instance()
	var terrainDust = terrainDustScene.instance()
	terrainDust.color = Color(1, 0.862745, 0.45098)
	terrainDust.planet = planet
	terrainDust.windSpeed = planet.windSpeed
	
	giantWorm.planet = planet
	giantWorm.terrainDustParticleSystem = terrainDust
	add_child(terrainDust)
	add_child(giantWorm)
	giantWorm.position.x = planet.size.x / 2.0
	giantWorm.position.y = planet.size.y * 2.0
	
	MaterialSetNoiseSeed(fogMaterial, "fogNoise")
	ApplyWindToMaterial(fogMaterial)
	
	fogMaterial = planet.terrain.PlaceExtraMaterial(fogMaterial, 1)
	
	planet.AddMaterialToUpdate(fogMaterial)
	
	terrainDust.raise()
	terrain.raise()
	


