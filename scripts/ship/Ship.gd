extends RigidBody5D
class_name Ship

## Current level
var level: Level

## This ship's state machine
var state_machine: ShipStateMachine

## Current thruster force
var thruster_force: float = 0.0

## Input for turning
var input_turn: float = 0.0

## Input for thruster
var input_thruster: float = 0.0

## Size of this ship (in meters)
@export var size: Vector2 = Vector2(3.0, 6.0)

## Max thruster force (in meters)
@export var max_thruster_force: float = 50.0

## Max turning speed (in meters/second)
@export var max_turning_speed: float = 90.0

## Thruster acceleration
@export var thruster_acceleration: float = 50.0

## Turning acceleration
@export var turning_acceleration: float = 90.0

## Turning decceleration
@export var turning_decceleration: float = 90.0

## Mass of the ship
@export var mass: float = 10.0

## Initialize this ship
func _init() -> void:
	super._init()
	Engine.time_scale = 1.0
	# Setup the state machine
	state_machine = ShipStateMachine.new()
	state_machine.setup()

## Called when entering the tree
func _enter_tree() -> void:
	level = get_parent().get_parent()

## Called when ready
func _ready() -> void:
	state_machine.initialize(self, "moving")

## Called to integrate forces
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	state_machine.process(ShipStateMachine.ProcessMode.INTEGRATE_FORCES, state.step, false)

## Called every frame
func _process(delta: float) -> void:
	# Get inputs
	input_turn = Input.get_axis("turn_left", "turn_right")
	input_thruster = Input.get_axis("thruster_decrease", "thruster_increase")

	# Process state machine
	state_machine.process(ShipStateMachine.ProcessMode.IDLE, delta)

## Called every physics frame
func _physics_process(delta: float) -> void:
	state_machine.process(ShipStateMachine.ProcessMode.PHYSICS, delta)
