extends PlanetGenerator

func PrepareGeneration() -> void:
	.PrepareGeneration()
	terrainMaterial = GameMaterials.GetMaterial("Planets/Glacya/Terrain")
	terrain.height = 100.0

func Generate() -> void:
	.Generate()
	
	planet.gravity = Vector2.DOWN * 110.0
	
	var fogMaterial = GameMaterials.GetMaterial("Planets/Glacya/Fog")
	
	MaterialSetNoiseSeed(fogMaterial, "fogNoise")
	ApplyWindToMaterial(fogMaterial)
	
	fogMaterial = planet.terrain.PlaceExtraMaterial(fogMaterial, 1)
	
	planet.AddMaterialToUpdate(fogMaterial)


