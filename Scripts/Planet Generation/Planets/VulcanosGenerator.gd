extends PlanetGenerator

func PrepareGeneration() -> void:
	.PrepareGeneration()
	terrainMaterial = GameMaterials.GetMaterial("Planets/Vulcanos/Terrain")
	terrain.height = 100.0

func Generate() -> void:
	.Generate()
	
	planet.gravity = Vector2.DOWN * 70.0
	
	var magmaMaterial = GameMaterials.GetMaterial("Planets/Vulcanos/Magma")
	var fogMaterial = GameMaterials.GetMaterial("Planets/Vulcanos/Fog")
	
	MaterialSetNoiseSeed(magmaMaterial, "text")
	MaterialSetNoiseSeed(fogMaterial, "fogNoise")
	ApplyWindToMaterial(fogMaterial)
	
	magmaMaterial = planet.terrain.PlaceExtraMaterial(magmaMaterial)
	fogMaterial = planet.terrain.PlaceExtraMaterial(fogMaterial, 1)
	
	planet.AddMaterialToUpdate(fogMaterial)


