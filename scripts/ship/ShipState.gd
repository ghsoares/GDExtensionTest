extends State
class_name ShipState

## Target body state
var body: PhysicsDirectBodyState2D

## Called every physics frame
func _process(mode: int, delta: float) -> void:
	if mode == ShipStateMachine.ProcessMode.INTEGRATE_FORCES:
		body = PhysicsServer2D.body_get_direct_state(target.get_rid())
