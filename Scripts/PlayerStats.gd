extends Node

var maxFuel: float = 500.0
var fuelLossRate: float = 0.1
var currentFuel: float setget SetCurrentFuel
var hasWaterThruster: bool = true

func _ready() -> void:
	Reset()

func Reset() -> void:
	currentFuel = maxFuel

func SetCurrentFuel(newFuel: float) -> void:
	currentFuel = newFuel
	currentFuel = clamp(currentFuel, 0.0, maxFuel)


