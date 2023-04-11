extends Control
class_name Game

## The game view
var view: GameView

## The game level
var level: Level

## Called when entering the tree
func _enter_tree() -> void:
	view = $View
	level = $View/View/Level
	Engine.time_scale = 1.0