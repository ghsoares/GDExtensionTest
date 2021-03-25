extends Node

class_name StateMachine

var states = {}
var currState = null
var querriedState = null
var root

func _ready() -> void:
	states = {}
	
	for c in get_children():
		if c is State:
			c.stateMachine = self
			states[c.name] = c

func start() -> void:
	changeState(states.values()[0])

func stop() -> void:
	currState = null
	querriedState = null

func queryState(var stateName: String):
	querriedState = states[stateName]
	return querriedState

func changeState(var state) -> void:
	if currState:
		currState.exit()
	currState = state
	currState.root = root
	currState.enter()

func _process(delta: float) -> void:
	querriedState = null
	if currState:
		currState.deltaTime = delta
		currState.process()
		if querriedState:
			changeState(querriedState)

func _physics_process(delta: float) -> void:
	querriedState = null
	if currState:
		currState.fixedDeltaTime = delta
		currState.physics_process()
		if querriedState:
			changeState(querriedState)
