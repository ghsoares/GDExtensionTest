tool
extends Node2D

class_name ParticleSystem2D

class Particle:
	var idx: int
	
	var position: Vector2
	var size: Vector2
	var rotation: float
	
	var gravityScale: float
	
	var velocity: Vector2
	var lifetime: float
	var life: float
	var color: Color
	
	var startSize: Vector2
	var startColor: Color
	
	var customData: Dictionary
	
	var alive: bool
	
	func GetTransform() -> Transform2D:
		var t := Transform2D.IDENTITY
		
		t = t.scaled(size)
		t = t.rotated(rotation)
		t.origin = position
		
		return t

enum UpdateMode {
	Process,
	PhysicsProcess
}

var particles := []
var currentDrawDelay := 0.0
var multimesh : MultiMesh
var aliveParticles := 0
var prevPos : Vector2
var currentVelocity : Vector2

export (bool) var emitting = true
export (int) var numParticles = 1024
export (float) var lifetime = 1.0
export (Vector2) var gravity = Vector2(0.0, 98.0)
export (float) var timeScale = 1.0
export (UpdateMode) var updateMode = UpdateMode.PhysicsProcess
export (float) var editorDrawFPS = 24.0
export (Mesh) var mesh: Mesh
export (Texture) var texture
export (bool) var debug

func ResetMultimesh() -> void:
	if mesh == null:
		multimesh = null
		return
	
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.color_format = MultiMesh.COLOR_FLOAT
	multimesh.mesh = mesh
	multimesh.instance_count = numParticles

func ResetParticles() -> void:
	aliveParticles = 0
	particles = []
	for i in range(numParticles):
		var part = Particle.new()
		part.customData = {}
		part.idx = i
		particles.append(part)

func ResetIfNeeded() -> void:
	if !particles or particles.size() != numParticles:
		ResetParticles()
	
	if !multimesh or multimesh.instance_count != numParticles or multimesh.mesh != mesh:
		ResetMultimesh()

func _ready() -> void:
	ResetParticles()

func _physics_process(delta: float) -> void:
	var stopWatch = Stopwatch.new("Particles Physics Process")
	if updateMode == UpdateMode.PhysicsProcess:
		ResetIfNeeded()
		UpdateSystem(delta * timeScale)
	if debug:
		stopWatch.Mark()

func _process(delta: float) -> void:
	var stopWatch = Stopwatch.new("Particles Process")
	if updateMode == UpdateMode.Process:
		ResetIfNeeded()
		UpdateSystem(delta * timeScale)
	
	if Engine.editor_hint:
		if editorDrawFPS > 0:
			currentDrawDelay += editorDrawFPS * delta
			if currentDrawDelay >= 1.0:
				if OS.is_window_focused(): update()
				currentDrawDelay = 0.0
		else: update()
	else: update()
	if debug:
		stopWatch.Mark()

func EmitParticle(override = {}, force: bool = false):
	if !emitting and !force: return
	for particle in particles:
		if !particle: continue
		if !particle.alive:
			aliveParticles += 1
			InitParticle(particle, override)
			particle.lifetime = particle.life
			particle.startSize = particle.size
			particle.startColor = particle.color
			break

func UpdateSystem(delta: float) -> void:
	currentVelocity = (global_position - prevPos) / delta
	prevPos = global_position
	
	for particle in particles:
		if !particle: continue
		if particle.alive:
			UpdateParticle(particle, delta)

func InitParticle(particle, override = {}) -> void:
	particle.customData.clear()
	
	particle.alive = true
	particle.life = override.get("life", lifetime)
	
	particle.gravityScale = 1.0
	
	particle.position = override.get("position", global_position)
	particle.size = override.get("size", Vector2.ONE)
	particle.rotation = override.get("rotation", 0.0)
	
	particle.velocity = override.get("velocity", Vector2.ZERO)
	
	particle.color = override.get("color", Color.white)

func UpdateParticle(particle, delta: float) -> void:
	particle.velocity += gravity * delta * particle.gravityScale
	particle.position += particle.velocity * delta
	particle.life -= delta
	particle.life = clamp(particle.life, 0.0, particle.lifetime)
	if particle.life <= 0.0:
		DestroyParticle(particle)

func DestroyParticle(particle) -> void:
	aliveParticles -= 1
	particle.alive = false

func _draw() -> void:
	var stopWatch = Stopwatch.new("Draw Particles")
	if visible:
		draw_set_transform_matrix(global_transform.affine_inverse())
		DrawParticles()
	if debug:
		stopWatch.Mark()

func DrawParticles() -> void:
	if multimesh:
		var visibleParticles = 0
		for part in particles:
			if part.alive:
				var t = part.GetTransform()
				
				multimesh.set_instance_transform_2d(visibleParticles, t)
				multimesh.set_instance_color(visibleParticles, part.color)
				visibleParticles += 1
		
		multimesh.visible_instance_count = visibleParticles
		
		draw_multimesh(multimesh, texture)

func DrawPolyline(pointTransforms: Array, color: Color) -> void:
	var count = pointTransforms.size()
	var pol = []
	var uvs = []
	
	for i in range(count):
		var t : Transform2D = pointTransforms[i]
		var p = t.origin - t.y
		var uvX = float(i) / float(count - 1)
		pol.append(p)
		uvs.append(Vector2(uvX, 0))
	
	var i = count - 1
	while i >= 0:
		var t : Transform2D = pointTransforms[i]
		var p = t.origin + t.y
		var uvX = float(i) / float(count - 1)
		pol.append(p)
		uvs.append(Vector2(uvX, 1.0))
		i -= 1
	
	if Geometry.triangulate_polygon(pol).size() == 0: return
	
	draw_colored_polygon(pol, color, uvs)






