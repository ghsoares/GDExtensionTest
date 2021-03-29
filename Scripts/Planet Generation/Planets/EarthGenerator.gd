extends PlanetGenerator

func PrepareGeneration() -> void:
	.PrepareGeneration()
	terrainMaterial = GameMaterials.GetMaterial("Planets/Earth/Terrain")

func Generate() -> void:
	.Generate()
	
	planet.gravity = Vector2.DOWN * 98.0
	
	var grassMaterial = GameMaterials.GetMaterial("Planets/Earth/Grass")
	var waterMaterial = GameMaterials.GetMaterial("Planets/Earth/Water")
	
	ApplyWindToMaterial(grassMaterial)
	ApplyWindToMaterial(waterMaterial)
	
	grassMaterial = planet.terrain.PlaceExtraMaterial(grassMaterial, -1)
	
	var materials = PlaceLiquidBodies(waterMaterial, 1.0)
	materials.append(grassMaterial)
	
	for mat in materials:
		planet.AddMaterialToUpdate(mat as ShaderMaterial)
	
	planet.terrain.raise()

