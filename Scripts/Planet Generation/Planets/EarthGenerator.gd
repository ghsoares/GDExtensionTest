extends PlanetGenerator

func _ready() -> void:
	._ready()
	terrainMaterial = GameMaterials.GetMaterial("Earth/Terrain")

func Generate() -> void:
	.Generate()
	
	var grassMaterial = GameMaterials.GetMaterial("Earth/Grass")
	var waterMaterial = GameMaterials.GetMaterial("Earth/Water")
	
	ApplyWindToMaterial(grassMaterial)
	ApplyWindToMaterial(waterMaterial)
	
	planet.terrain.PlaceExtraMaterial(grassMaterial, -1)
	
	PlaceLiquidBodies(waterMaterial)
	
	planet.terrain.raise()

