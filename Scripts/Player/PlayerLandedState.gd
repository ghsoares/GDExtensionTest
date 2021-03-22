extends State

func physics_process() -> void:
	if Input.is_action_just_pressed("next_level"):
		root.planet.Generate()
