extends StateMachine
class_name ShipStateMachine

## Process modes
enum ProcessMode {
	IDLE, PHYSICS, INTEGRATE_FORCES
}

## Setup this state machine
func setup() -> void:
	# Add the states
	add_state("moving", ShipMovingState.new())

