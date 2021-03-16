tool
extends ParticleSystem2D

var currentRate := 0.0

export (float) var rate := 1.0
export (float) var coneAngle := 15.0
export (Vector2) var velocityRange := Vector2(32, 64)
export (String) var text = "Hello World!"
export (Font) var font
export (Curve) var sizeCurve
export (Gradient) var gradient
export (float) var gradientFrequency

func _ready() -> void:
	if !Engine.editor_hint:
		rate = 0.0
		emitting = true

func UpdateSystem(delta: float) -> void:
	.UpdateSystem(delta)
	currentRate += rate * delta
	while currentRate >= 1.0:
		EmitParticle()
		currentRate -= 1.0

func InitParticle(particle, override = {}) -> void:
	.InitParticle(particle, override)
	
	var a = deg2rad(rand_range(-coneAngle, coneAngle))
	var dir := Vector2.UP.rotated(a)
	var speed = override.get("speed", rand_range(velocityRange.x, velocityRange.y))
	
	particle.velocity = dir * speed
	particle.customData["text"] = override.get("text", text)
	particle.customData["font"] = override.get("font", font)
	particle.customData["gradient"] = override.get("gradient", gradient)
	particle.customData["gradientFrequency"] = override.get("gradientFrequency", gradientFrequency)

func UpdateParticle(particle, delta: float) -> void:
	.UpdateParticle(particle, delta)
	var lifeT = particle.life / particle.lifetime
	
	var gradient = particle.customData["gradient"]
	
	if gradient:
		var uvX = lifeT * particle.customData["gradientFrequency"]
		uvX -= floor(uvX)
		var col = gradient.interpolate(uvX)
		particle.color = col
	if sizeCurve:
		var s = sizeCurve.interpolate(lifeT)
		particle.size = particle.startSize * s

func DrawParticles() -> void:
	.DrawParticles()
	var globalTransform = global_transform.affine_inverse()
	for particle in particles:
		if !particle.alive: continue
		
		var t = globalTransform
		
		var text = particle.customData.text
		var font = particle.customData.font
		var textSize = font.get_string_size(text)
		
		var pos = particle.position
		pos -= textSize * Vector2(.5, -.5) * particle.size
		
		t.origin = globalTransform.xform(pos)
		
		t.y *= particle.size
		t.x *= particle.size
		
		draw_set_transform_matrix(t)
		
		draw_string(particle.customData.font, Vector2.ZERO, particle.customData.text, particle.color)














