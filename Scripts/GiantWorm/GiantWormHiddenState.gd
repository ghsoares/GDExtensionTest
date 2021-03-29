extends State

var currTime := 0.0

export (float) var time := 5.0

func enter() -> void:
	currTime = time
	root.velocity = Vector2.ZERO

func physics_process() -> void:
	currTime -= fixedDeltaTime
	if currTime <= 0.0:
		queryState("Jump")

func exit() -> void:
	root.show()
