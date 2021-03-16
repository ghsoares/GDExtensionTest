extends Control

export (float) var pixelSize = 1.0
export (Vector2) var platformZoomDistanceRange = Vector2(32.0, 128.0)
export (Vector2) var platformZoomRange = Vector2(1.0, .5)
export (float) var zoomLerping = 8.0
export (float) var maxShockwaveEnergy = 16.0
export (float) var maxShockwaveFrequency = 8.0
export (float, EASE) var t = 1.0

var explosions = []

onready var world = $View/World
onready var view = $View
onready var cam = $Camera
onready var ui = $UI
onready var viewTexMaterial = $ViewTex.material

func _ready() -> void:
	world.connect("world_generated", self, "OnWorldGenerated")
	world.game = self
	ui.world = world
	PlayerStats.Start()

func _process(delta: float) -> void:
	UpdateViewport()
	if world.generating: return
	
	if !Engine.editor_hint:
		UpdateCamera(delta)
		UpdateViewMaterial(delta)

func UpdateCamera(delta: float) -> void:
	cam.limit_right = rect_size.x
	cam.limit_bottom = rect_size.y
	
	var onViewPos = world.camera.get_global_transform_with_canvas().origin * pixelSize
	
	var playerPos = world.player.global_position
	var platforms = world.platformPlacer.platforms
	
	var dst = platformZoomDistanceRange.y
	
	for p in platforms:
		var thisDst = (p.global_position - playerPos).length()
		if thisDst < dst:
			dst = thisDst
	
	var t = (dst - platformZoomDistanceRange.x) / (platformZoomDistanceRange.y - platformZoomDistanceRange.x)
	t = clamp(t, 0, 1)
	var z = lerp(platformZoomRange.y, platformZoomRange.x, t)
	
	cam.position = onViewPos
	cam.zoom = cam.zoom.linear_interpolate(Vector2.ONE * z, clamp(delta * zoomLerping, 0, 1))

func Explosion(pos: Vector2, radius: float, energy: float, frequency: float, life: float) -> void:
	explosions.append({
		"position": pos,
		"radius": radius,
		"energy": energy,
		"frequency": frequency,
		"life": life,
		"startLife": life
	})

func UpdateViewMaterial(delta: float) -> void:
	var t = view.canvas_transform.affine_inverse()
	viewTexMaterial.set_shader_param("cameraMat", t)
	viewTexMaterial.set_shader_param("numShockWaves", explosions.size())
	viewTexMaterial.set_shader_param("maxShockwaveEnergy", maxShockwaveEnergy)
	viewTexMaterial.set_shader_param("maxShockwaveFrequency", maxShockwaveFrequency)
	viewTexMaterial.set_shader_param("mapSize", world.terrain.size)
	
	if explosions.size() == 0:
		return
	
	var explosionData := Image.new()
	explosionData.create(explosions.size(), 2, false, Image.FORMAT_RGBAF)
	
	explosionData.lock()
	
	var idx = 0
	var newExplosions = []
	
	for explosion in explosions:
		explosion["life"] -= delta
		explosion["life"] = max(explosion["life"], 0.0)
		
		var explosionPos = explosion["position"] / world.terrain.size
		var explosionRadius = explosion["radius"] / max(world.terrain.size.x, world.terrain.size.y)
		var explosionEnergy = explosion["energy"] / maxShockwaveEnergy
		var explosionFrequency = explosion["frequency"] / maxShockwaveFrequency
		var life = explosion["life"] / explosion["startLife"]
		
		explosionData.set_pixel(idx, 0, Color(explosionPos.x, explosionPos.y, explosionRadius, explosionEnergy))
		explosionData.set_pixel(idx, 1, Color(explosionFrequency, life, 0.0))
		
		if explosion["life"] > 0.0:
			newExplosions.append(explosion)
		
		idx += 1
	
	explosions = newExplosions
	
	explosionData.unlock()
	
	var explosionDataTex := ImageTexture.new()
	explosionDataTex.create_from_image(explosionData, 0)
	
	viewTexMaterial.set_shader_param("shockwaves", explosionDataTex)

func UpdateViewport() -> void:
	view.size = rect_size / pixelSize;
	view.set_size_override(true, rect_size);
	view.size_override_stretch = true;

func OnWorldGenerated() -> void:
	cam.zoom = Vector2.ONE
	Transition.Animate(true)




