extends Node2D

class_name ParticleSystem

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
var externalForces : Vector2

export (bool) var emitting = true
export (bool) var local = false
export (int) var numParticles = 1024
export (float) var lifetime = 1.0
export (Color) var color = Color.white
export (Vector2) var gravity = Vector2(0.0, 98.0)
export (float) var timeScale = 1.0
export (UpdateMode) var updateMode = UpdateMode.PhysicsProcess
export (float) var editorDrawFPS : float = 24.0
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
	ResetMultimesh()

func AddForce(force: Vector2) -> void:
	externalForces += force

func _physics_process(delta: float) -> void:
	if updateMode == UpdateMode.PhysicsProcess:
		ResetIfNeeded()
		UpdateSystem(delta * timeScale)

func _process(delta: float) -> void:
	if updateMode == UpdateMode.Process:
		ResetIfNeeded()
		UpdateSystem(delta * timeScale)
	
	update()

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
			UpdateParticle(particle, 0.0)
			break

func UpdateSystem(delta: float) -> void:
	currentVelocity = (global_position - prevPos) / delta
	prevPos = global_position
	
	for particle in particles:
		if !particle: continue
		if particle.alive:
			UpdateParticle(particle, delta)
	
	externalForces = Vector2.ZERO

func InitParticle(particle, override = {}) -> void:
	particle.customData.clear()
	
	particle.alive = true
	particle.life = override.get("life", lifetime)
	
	particle.gravityScale = 1.0
	
	if local:
		particle.position = override.get("position", Vector2.ZERO)
	else:
		particle.position = override.get("position", global_position)
	
	particle.size = override.get("size", Vector2.ONE)
	particle.rotation = override.get("rotation", 0.0)
	
	particle.velocity = override.get("velocity", Vector2.ZERO)
	
	particle.color = override.get("color", color)

func UpdateParticle(particle, delta: float) -> void:
	particle.velocity += externalForces * delta
	particle.velocity += gravity * delta * particle.gravityScale
	particle.position += particle.velocity * delta
	particle.life -= delta
	particle.life = clamp(particle.life, 0.0, particle.lifetime)
	if particle.life <= 0.0:
		DestroyParticle(particle)
		aliveParticles -= 1
		particle.alive = false

func DestroyParticle(particle) -> void:
	pass

func _draw() -> void:
	if visible:
		draw_circle(Vector2.ZERO, 0.0, Color.white)
		if !local: draw_set_transform_matrix(global_transform.affine_inverse())
		DrawParticles()

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
