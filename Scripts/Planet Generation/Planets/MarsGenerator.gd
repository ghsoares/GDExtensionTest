extends PlanetGenerator

func _ready() -> void:
	._ready()
	terrainMaterial = GameMaterials.GetMaterial("Planets/Mars/Terrain")

func Generate() -> void:
	.Generate()
	
	planet.gravity = Vector2.DOWN * 37.0
	
	var fogMaterial = GameMaterials.GetMaterial("Planets/Mars/Fog")
	
	MaterialSetNoiseSeed(fogMaterial, "fogNoise")
	ApplyWindToMaterial(fogMaterial)
	
	planet.terrain.PlaceExtraMaterial(fogMaterial, 1)
