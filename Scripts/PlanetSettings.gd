tool
extends Node

class_name PlanetSettings

var currentWindSpeed := Vector2.RIGHT * 16.0

export (float) var gravityScale = 98.0

export (OpenSimplexNoise) var heightMapNoise
export (NoiseTexture) var terrainTexture
export (GradientTexture) var terrainGradient
export (float) var terrainResolution = 1.0/4.0
export (float) var terrainHeight = 256.0
export (float) var terrainHeightOffset = 128.0
export (float) var terrainTextureEasing = -2.0
export (float) var terrainTextureTiling = 128.0
export (float) var terrainWarpTiling = 256.0
export (float) var terrainWarpAmount = 16.0
export (float) var terrainTextureSteps = 8.0
export (Vector2) var terrainFadeRange = Vector2(32, 256)
export (Vector3) var terrainFadeValues = Vector3(1, .5, 0)
export (float, 0, 1) var waterBodiesRate = .5
export (Vector2) var waterBodiesHeightRange = Vector2(32.0, 64.0)
export (ShaderMaterial) var waterBodiesMaterial
export (ShaderMaterial) var baseMaterial
export (Array, ShaderMaterial) var terrainExtraMaterials = []
