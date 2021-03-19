tool
extends Control

class_name GameWorld

var game
var rng: RandomNumberGenerator

var root

var editorGenerateTimer = 0.0
var planetCollection
var peakValleys
var waterPlacer
var platformPlacer
var terrain
var player
var waterSplashParticles
var camera
var prevSettingsIdx = -1
var settings

var generating = false

export (Vector2) var worldSize := Vector2(1024, 600)
export (float) var margin := 64.0
export (int) var settingsIdx := 0 setget SetSettingsIdx
export (float) var generateDelay = 1.0
export (bool) var generateWithDelay = false
export (bool) var generate setget SetGenerate
export (float) var playerStartPosY = 32.0

onready var terrainScene = preload("res://Scenes/Terrain.tscn")
onready var playerScene = preload("res://Scenes/Player.tscn")
onready var waterSplashScene = preload("res://Scenes/WaterSplash.tscn")

signal world_generated()

func GetResources() -> void:
	planetCollection = get_node_or_null("PlanetCollection")
	root = get_node_or_null("Root")
	if !terrainScene:
		terrainScene = load("res://Scenes/Terrain.tscn")

func SetSettingsIdx(var idx: int) -> void:
	GetResources()
	idx = max(idx, 0)
	if planetCollection == null:
		settingsIdx = idx
		return
	if planetCollection.settings.size() == 0:
		settingsIdx = 0
		return
	idx = clamp(idx, 0, planetCollection.settings.size() - 1)
	settingsIdx = idx

func SetGenerate(var gen: bool) -> void:
	GetResources()
	Generate()

func _ready() -> void:
	randomize()
	if Engine.editor_hint:
		rng = RandomNumberGenerator.new()
		rng.seed = randi()
	else:
		#var sed = InputRecorder.GetSessionData("GameSeed", randi())
		var sed = randi()
		rng = RandomNumberGenerator.new()
		rng.seed = sed
	
	GetResources()
	Generate()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_select"):
		get_tree().paused = false
	
	if Engine.editor_hint and generateWithDelay:
		editorGenerateTimer += delta
		if editorGenerateTimer >= generateDelay:
			GetResources()
			Generate()
			editorGenerateTimer = 0.0

func RandomSettings():
	var available = [0, 1, 2, 3, 4] + PlayerSave.unlockedPlanets
	var idx = available[rng.randi() % available.size()]
	
	while idx == prevSettingsIdx and available.size() > 1:
		idx = available[rng.randi() % available.size()]
	
	prevSettingsIdx = idx
	
	return idx

func Generate() -> void:
	if !rng:
		rng = RandomNumberGenerator.new()
		rng.seed = randi()
	
	if !planetCollection or planetCollection.settings.size() == 0: return
	if generating: return
	
	margin = WorldCamera.MAX_CAMERA_SHAKE
	
	generating = true
	
	for c in get_children():
		if c == planetCollection or c == root: continue
		c.queue_free()
	
	if !Engine.editor_hint:
		settingsIdx = RandomSettings()
	
	settings = planetCollection.settings[settingsIdx]
	
	var windSpeed = rng.randf_range(settings.windSpeedRange.x, settings.windSpeedRange.y)
	
	var totalSize = worldSize + Vector2.ONE * margin * 2.0
	
	rect_position = Vector2.ZERO
	rect_size = totalSize
	
	var sed = rng.randi()
	
	settings = planetCollection.settings[settingsIdx]
	settings.heightMapNoise.seed = sed
	settings.terrainTexture.noise.seed = sed
	settings.currentWindSpeed = windSpeed
	
	if !Engine.editor_hint: 
		yield(SignalWaiter.new([settings.terrainTexture], ["changed"]), "finished")
	
	peakValleys = PeakValleys.new()
	waterPlacer = WaterPlacer.new()
	platformPlacer = PlatformPlacer.new()
	terrain = terrainScene.instance()
	
	peakValleys.world = self
	waterPlacer.world = self
	platformPlacer.world = self
	terrain.world = self
	
	add_child(platformPlacer)
	add_child(peakValleys)
	
	terrain.size = totalSize
	terrain.planetSettings = settings
	
	platformPlacer.Generate()
	peakValleys.GetPeakAndValleys()
	
	if !Engine.editor_hint:
		camera = WorldCamera.new()
		player = playerScene.instance()
		waterSplashParticles = waterSplashScene.instance()
		
		camera.limit_left = margin
		camera.limit_top = margin
		camera.limit_bottom = worldSize.y
		camera.limit_right = worldSize.x
		
		player.world = self
		player.position = Vector2(totalSize.x / 2.0, playerStartPosY + margin)
		
		add_child(camera)
		add_child(player)
		add_child(waterSplashParticles)
	
	add_child(waterPlacer)
	add_child(terrain)
	
	waterPlacer.Generate()
	terrain.Generate()
	
	generating = false
	
	emit_signal("world_generated")





