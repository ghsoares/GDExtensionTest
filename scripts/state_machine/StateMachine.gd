extends RefCounted
class_name StateMachine

## All registered states
var states: Dictionary

## Current queried state
var queried_state: State

## Reprocess queried state
var reprocess_state: bool

## Current running state
var running_state: State

## Current target
var target

## Register a new state to the state machine
func add_state(name: String, state: State) -> void:
	states[name] = state
	state.name = name
	state.state_machine = self

## Gets a state by name
func get_state(name: String) -> State:
	assert(states.has(name), "State machine doesn't have a state named '%s'" % name)
	return states[name]

## Override a state by name
func override_state(name: String, state: State) -> void:
	assert(states.has(name), "State machine doesn't have a state named '%s'" % name)
	states[name] = state
	state.name = name
	state.state_machine = self

## Remove a state by name
func remove_state(name: String) -> void:
	assert(states.has(name), "State machine doesn't have a state named '%s'" % name)
	states.erase(name)

## Initialize the state machine
func initialize(target, start_state) -> void:
	assert(start_state is String or start_state is State, "Start state must be a String or State")

	# Set this state machine target
	self.target = target

	# For each registered state
	for state in states.values():
		state.target = target
		state._initialize()
	
	# Change to start state
	if start_state is String: start_state = get_state(start_state)
	change_state(start_state)

## Queries a state
func query(state, reprocess: bool = false) -> State:
	assert(state is String or state is State, "State must be a String or State")
	if state is String: state = get_state(state)
	queried_state = state
	reprocess_state = reprocess
	return state

## Gets current queried state
func queried() -> State:
	return queried_state

# Transitionate state to the new state
func change_state(to_state: State) -> void:
	assert(to_state != null, "New state is null")

	# Exits the current state
	if running_state != null:
		running_state.next_state = to_state
		running_state._exit()

	# Enters the new state
	to_state.prev = running_state
	running_state = to_state
	to_state._enter()

## Process the state machine every frame
func process(delta: float, transitionate: bool = false) -> void:
	assert(running_state != null, "Current state is null")

	# Has queried state
	if queried_state and transitionate:
		change_state(queried_state)
		queried_state = null

	# While needing to reprocess
	while true:
		# Process the state
		running_state._process(delta)

		# Has queried state
		if queried_state and transitionate:
			change_state(queried_state)
			queried_state = null
			# Needs to reprocess
			if reprocess_state:
				reprocess_state = false
				continue
		
		break

# Physics process the current state
func physics_process(delta: float, transitionate: bool = true) -> void:
	assert(running_state != null, "Current state is null")

	# Has queried state
	if queried_state and transitionate:
		change_state(queried_state)
		queried_state = null

	# While needing to reprocess
	while true:
		# Process the state
		running_state._physics_process(delta)

		# Has queried state
		if queried_state and transitionate:
			change_state(queried_state)
			queried_state = null
			# Needs to reprocess
			if reprocess_state:
				reprocess_state = false
				continue
		
		break
