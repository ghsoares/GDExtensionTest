extends PlanetGenerator

var fishesParticleSystem

func PrepareGeneration() -> void:
	.PrepareGeneration()
	fishesParticleSystem = preload("res://Scenes/ParticleSystems/Fishes.tscn")
	windSpeedRange = Vector2(32.0, 64.0)
	terrainMaterial = GameMaterials.GetMaterial("Planets/Aquantis/Terrain")
	terrain.height = 100.0

func Generate() -> void:
	.Generate()
	
	planet.gravity = Vector2.DOWN * 120.0
	var algaeMaterial = GameMaterials.GetMaterial("Planets/Aquantis/Algae")
	var waterMaterial = GameMaterials.GetMaterial("Planets/Aquantis/Water")
	var fishes = fishesParticleSystem.instance()
	
	ApplyWindToMaterial(waterMaterial)
	
	algaeMaterial = planet.terrain.PlaceExtraMaterial(algaeMaterial, -1)
	
	liquidPlacer.material = waterMaterial
	var floodedLiquid = liquidPlacer.Flood(256)
	
	fishes.planet = planet
	fishes.rectSize = floodedLiquid.rect_size
	fishes.position.y = floodedLiquid.rect_position.y
	add_child(fishes)
	
	planet.AddMaterialToUpdate(floodedLiquid.material)
	planet.AddMaterialToUpdate(algaeMaterial)
	
	liquidPlacer.raise()
	terrain.raise()


