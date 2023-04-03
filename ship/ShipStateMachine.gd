extends StateMachine
class_name ShipStateMachine

## Setup this state machine
func setup() -> void:
	# Add the states
	add_state("moving", ShipMovingState.new())

