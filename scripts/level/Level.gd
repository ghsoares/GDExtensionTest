extends Node3D
class_name Level

## Main game level script

## The main terrain of this level
var terrain: LevelTerrain

## The main camera of this level
var camera: LevelCamera

## Pixel size
@export var pixel_size: float = 0.01

## Called when entering the tree
func _enter_tree() -> void:
	# Get the nodes
	terrain = $Terrain
	camera = $Camera


