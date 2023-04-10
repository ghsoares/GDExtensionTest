extends Node3D
class_name Level

## Main game level script

## The main terrain of this level
var terrain: LevelTerrain

## The main camera of this level
var camera: LevelCamera

## The planets root
var planets_root: Node3D

## The level ship
var ship: Ship

## The level planets
var planets: Array[LevelPlanet]

## Called when entering the tree
func _enter_tree() -> void:
	# Get the nodes
	terrain = $Terrain
	camera = $Camera
	planets_root = $Planets
	ship = $Ships/Ship
	planets.assign(planets_root.get_children())

## Called when ready
func _ready() -> void:
	# Initialize all currently added planets
	for planet in planets:
		planet.level = self
		planet.initialize()

## Adds a planet
func add_planet(planet: LevelPlanet) -> void:
	planets.append(planet)

	# Add as child
	planets_root.add_child(planet)

	# Initialize the planet
	planet.level = self
	planet.initialize()

	# Get the planet bounds
	var bounds: Rect2 = planet.bounds

## Removes a planet
func remove_planet(planet: LevelPlanet) -> void:
	planets.erase(planet)

	# Remove as child
	planets_root.remove_child(planet)

	# Get the planet bounds
	var bounds: Rect2 = planet.bounds

	# Queue free planet
	planet.queue_free()

