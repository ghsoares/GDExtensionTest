extends State
class_name ShipState

## Target body state
var body_state: PhysicsDirectBodyState2D

## Called every physics frame
func _physics_process(delta: float) -> void:
	body_state = target.get_body_state()

## Apply impulse to the ship
func apply_impulse(o: Vector2, j: Vector2) -> void:
	body_state.apply_impulse(o, j)

## Apply central impulse to the ship
func apply_central_impulse(j: Vector2) -> void:
	body_state.apply_central_impulse(j)
	
## Apply force to the ship
func apply_force(o: Vector2, f: Vector2) -> void:
	body_state.apply_force(o, f)

## Apply central force to the ship
func apply_central_force(f: Vector2) -> void:
	body_state.apply_central_force(f)
