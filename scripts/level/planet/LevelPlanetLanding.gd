extends Node3D
class_name LevelPlanetLanding

# The model
var model: Node3D

# Landing size
var size: float

# Score multiplier
var score_multiplier: float = 1.0

# Called when entering the tree
func _enter_tree() -> void:
	# Get model and set it's size
	model = $Model
	model.transform.basis.x.x = size
