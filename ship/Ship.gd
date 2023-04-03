extends RigidBody5D
class_name Ship

## Current level
var level: Level

## This ship's state machine
var state_machine: ShipStateMachine

## Size of this ship
@export var size: Vector2 = Vector2(3.0, 6.0)

## Initialize this ship
func _init() -> void:
	super._init()
	# Setup the state machine
	state_machine = ShipStateMachine.new()
	state_machine.setup()

## Called when entering the tree
func _enter_tree() -> void:
	level = get_parent().get_parent()

## Called when ready
func _ready() -> void:
	state_machine.initialize(self, "moving")

## Called every frame
func _process(delta: float) -> void:
	state_machine.process(delta)

## Called every physics frame
func _physics_process(delta: float) -> void:
	state_machine.physics_process(delta)
