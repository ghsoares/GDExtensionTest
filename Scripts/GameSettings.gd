extends Node

var bloom: bool = false
var chromaticAberration: bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			if event.alt and event.control and event.scancode == KEY_B:
				bloom = !bloom
			if event.alt and event.control and event.scancode == KEY_C:
				chromaticAberration = !chromaticAberration
