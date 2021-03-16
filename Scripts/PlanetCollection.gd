tool
extends Node

class_name PlanetCollection

var settings : Array = []

func _ready() -> void:
	GetSettings()

func _process(var delta) -> void:
	if Engine.editor_hint:
		if get_child_count() != settings.size():
			GetSettings()

func GetSettings() -> void:
	settings.clear()
	for n in get_children():
		if n is PlanetSettings:
			settings.append(n)
