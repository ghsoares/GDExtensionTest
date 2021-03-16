extends Node

class_name State

var stateMachine
var deltaTime
var fixedDeltaTime
var root

func queryState(var stateName: String):
	return stateMachine.queryState(stateName)

func enter() -> void:
	pass

func physics_process() -> void:
	pass

func process() -> void:
	pass

func exit() -> void:
	pass
