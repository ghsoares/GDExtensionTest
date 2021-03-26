extends Control

class_name Liquid

var bodies = []

var currentSplashRate = 0.0

export (float) var drag = 1.0
export (float) var splashRatePerVelocity = 1.0
export (Vector2) var onSplashAmountRange = Vector2(8, 16)

onready var area := $Area
onready var areaCol := $Area/Col
onready var splashParticle := $Splash

func _ready() -> void:
	var rectShape := RectangleShape2D.new()
	rectShape.extents = rect_size * .5
	
	areaCol.shape = rectShape
	areaCol.position = rect_size / 2.0
	
	area.connect("body_entered", self, "OnBodyEntered")
	area.connect("body_exited", self, "OnBodyExited")

func _physics_process(delta: float) -> void:
	for body in bodies:
		var dragForce: Vector2 = body.linear_velocity
		
		dragForce *= clamp(drag * delta, 0.0, 1.0)
		
		var vel = body.linear_velocity.length()
		var diff = abs(body.global_position.y - rect_global_position.y)
		if diff <= 16.0:
			currentSplashRate += abs(vel) * splashRatePerVelocity * delta
		
		body.linear_velocity -= dragForce
		
		while currentSplashRate >= 1.0:
			var velocity = Vector2(-body.linear_velocity.x, -vel * 2.0) / (1.0 + drag)
			velocity *= rand_range(.5, 1.0) * .5
			velocity.x = clamp(velocity.x, -64, 64)
			var pos = body.global_position
			pos.y = rect_global_position.y + 4.0
			pos = splashParticle.to_local(pos)
			splashParticle.EmitParticle({"position": pos, "velocity": velocity})
			currentSplashRate -= 1.0

func OnBodyEntered(body) -> void:
	if body is RigidBody2D:
		bodies.append(body)
		body.set("insideWater", true)
		if body.linear_velocity.length_squared() > 0.25:
			var amount = int(rand_range(onSplashAmountRange.x, onSplashAmountRange.y + 1))
			var vel = body.linear_velocity.length() / (1.0 + drag)
			var pos = body.global_position
			pos.y = rect_global_position.y + 4.0
			vel *= rand_range(.5, 1.0) * .5
			pos = splashParticle.to_local(pos)
			for i in range(amount):
				splashParticle.EmitParticle({"position": pos, "velocity": Vector2.UP * vel})
		body.linear_velocity /= (1.0 + drag)

func OnBodyExited(body) -> void:
	if body is RigidBody2D:
		if !body.is_inside_tree(): return
		if !splashParticle.is_inside_tree(): return
		bodies.erase(body)
		body.set("insideWater", false)
		if body.linear_velocity.length_squared() > 0.25:
			var amount = int(rand_range(onSplashAmountRange.x, onSplashAmountRange.y + 1))
			var vel = body.linear_velocity.length() * (1.0 + drag)
			var pos = body.global_position
			pos.y = rect_global_position.y + 4.0
			vel *= rand_range(.5, 1.0) * .5
			pos = splashParticle.to_local(pos)
			for i in range(amount):
				splashParticle.EmitParticle({"position": pos, "velocity": Vector2.UP * vel})



