extends Control
class_name GameUI

## The UI game
var game: Game

## Called when entering the tree
func _enter_tree() -> void:
	game = get_parent()

## Called every frame
func _process(delta: float) -> void:
	# The level
	var level: Level = game.level

	# The player ship
	var ship: Ship = level.ship




