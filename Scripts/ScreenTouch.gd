extends Control

var touchID = -1

export (String) var action : String = ""
export (Color) var pressedColor = Color.white
export (Color) var releasedColor = Color(1.0, 1.0, 1.0, .5)
export (float) var colorLerp = 4.0

func _input(event: InputEvent) -> void:
	if !visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if get_global_rect().has_point(event.position):
				Input.action_press(action)
				touchID = event.index
		else:
			if event.index == touchID:
				touchID = -1
				Input.action_release(action)

func _process(delta: float) -> void:
	var desiredModulate = releasedColor
	if Input.is_action_pressed(action):
		desiredModulate = pressedColor
	
	modulate = modulate.linear_interpolate(desiredModulate, clamp(colorLerp * delta, 0, 1))



