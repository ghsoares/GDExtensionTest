extends CanvasLayer

onready var fuelLabel := $UI/Fuel

func _process(delta: float) -> void:
	fuelLabel.text = str(ceil(PlayerStats.currentFuel)) + "/" + str(ceil(PlayerStats.maxFuel))
	pass
