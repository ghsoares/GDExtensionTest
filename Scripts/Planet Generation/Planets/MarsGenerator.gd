extends PlanetGenerator

func PrepareGeneration() -> void:
	.PrepareGeneration()
	terrainMaterial = GameMaterials.GetMaterial("Planets/Mars/Terrain")
	noise.period = 192
	noise.octaves = 4
	terrain.height = 400.0

func Generate() -> void:
	.Generate()
	
	planet.gravity = Vector2.DOWN * 37.0
	
	var fogMaterial = GameMaterials.GetMaterial("Planets/Mars/Fog")
	
	MaterialSetNoiseSeed(fogMaterial, "fogNoise")
	ApplyWindToMaterial(fogMaterial)
	
	fogMaterial = planet.terrain.PlaceExtraMaterial(fogMaterial, 1)
	
	planet.AddMaterialToUpdate(fogMaterial)
