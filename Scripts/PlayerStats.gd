extends Node

var levelsPassed := 0
var deaths := 0
var perfects := 0
var perfectsStreak := 0
var highestPerfectsStreak := 0
var totalScore := 0
var fuel := 0.0 setget SetFuel
var maxFuel := 500.0
var fuelLoseRate := .1
var fuelPercentageWarning = .1

func Start() -> void:
	fuel = maxFuel

func PerfectsStreakBreak() -> void:
	highestPerfectsStreak = max(highestPerfectsStreak, perfectsStreak)
	perfectsStreak = 0

func SetFuel(newFuel: float) -> void:
	newFuel = clamp(newFuel, 0.0, maxFuel)
	fuel = newFuel
	pass
