extends RefCounted
class_name State

## Parent state machine
var state_machine: StateMachine

## This state name
var name: String

## Previously running state
var prev: State

## Next state
var next: State

## Current target
var target

## Override this function to change how this state behaves when entering as
## current state
func _enter() -> void: pass

## Override this function to change how this state behaves when exiting as
## current state
func _exit() -> void: pass

## Override this function to change how this state is initialized
func _initialize() -> void: pass

## Override this function to execute a behaviour based on process mode
func _process(mode: int, delta: float) -> void: pass

## Query to the target state
func query(state, reprocess: bool = false) -> State:
	return state_machine.query(state, reprocess)

## Get queried state
func queried() -> State:
	return state_machine.queried()


