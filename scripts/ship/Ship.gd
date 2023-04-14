@tool
extends RigidBodySpatial2D
class_name Ship

## Current level
var level: Level

## This ship state machine
var state_machine: ShipStateMachine

## This ship fuel
var fuel: float = 0.0

## Current thruster force
var thruster_force: float = 0.0

## Input for turning
var input_turn: float = 0.0

## Input for thruster
var input_thruster: float = 0.0

## Size of this ship (in meters)
@export var size: Vector2 = Vector2(3.0, 6.0)

## Max fuel
@export var max_fuel: float = 40000.0

## Fuel/force usage ratio
@export var fuel_usage_ratio: float = 1.0

## Max thruster force (in meters)
@export var max_thruster_force: float = 1000.0

## Max turning speed (in meters/second)
@export var max_turning_speed: float = 90.0

## Thruster acceleration
@export var thruster_acceleration: float = 250.0

## Turning acceleration
@export var turning_acceleration: float = 90.0

## Max landing velocity
@export var landing_max_velocity: float = 128.0

## Max landing rotation
@export var landing_max_rotation: float = 15.0

## Landing score min velocity
@export var landing_score_velocity: float = 64.0

## Landing score min rotation
@export var landing_score_rotation: float = 5.0

## Landing super score velocity
@export var landing_super_score_velocity: float = 32.0

## Landing super socre rotation
@export var landing_super_score_rotation: float = 3.0

## Initialize this ship
func _init() -> void:
	super._init()
	if not Engine.is_editor_hint():
		# Setup the state machine
		state_machine = ShipStateMachine.new()
		state_machine.setup()

## Called when entering the tree
func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		level = get_parent().get_parent()

## Called when ready
func _ready() -> void:
	if not Engine.is_editor_hint():
		# Set fuel to max
		fuel = max_fuel

		state_machine.initialize(self, "hovering")

## Called to integrate forces
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if not Engine.is_editor_hint():
		state_machine.process(ShipStateMachine.ProcessMode.INTEGRATE_FORCES, state.step, false)

## Called every frame
func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		# Get inputs
		input_turn = Input.get_axis("turn_left", "turn_right")
		input_thruster = Input.get_axis("thruster_decrease", "thruster_increase")

		# Process state machine
		state_machine.process(ShipStateMachine.ProcessMode.IDLE, delta)

## Called every physics frame
func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		state_machine.process(ShipStateMachine.ProcessMode.PHYSICS, delta)
