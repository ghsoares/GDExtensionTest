extends Control
class_name Game

## The game view
var view: GameView

## The game UI
var ui: GameUI

## The game level
var level: Level

## Called when entering the tree
func _enter_tree() -> void:
	view = $View
	ui = $UI
	level = $View/View/Level





