extends CanvasLayer

var showScore := 0.0
var showFuel := 0.0
var showMaxFuel := 0.0
var showFps := 0.0
var fuelWarning = false

onready var debug = $Debug
onready var scoreText = $PlayerStats/Score/HBox/ScoreTex
onready var fuelText = $PlayerStats/Fuel/HBox/FuelTex
onready var maxFuelText = $PlayerStats/Fuel/HBox/MaxFuel
onready var fuelWarningAnim = $PlayerStats/Fuel/Warning/Anim
onready var world = $"../View/World"

func _ready() -> void:
	fuelWarningAnim.play("Anim")
	fuelWarningAnim.advance(0)
	fuelWarningAnim.stop()
	world.connect("world_generated", self, "OnWorldGenerated")

func _process(delta: float) -> void:
	showScore = lerp(showScore, PlayerStats.totalScore, delta * 4.0)
	showFuel = lerp(showFuel, PlayerStats.fuel, delta * 4.0)
	showMaxFuel = lerp(showMaxFuel, PlayerStats.maxFuel, delta * 4.0)
	
	var perc = PlayerStats.fuel / PlayerStats.maxFuel
	
	scoreText.text = str(round(showScore))
	fuelText.text = str(round(showFuel))
	maxFuelText.text = str(round(showMaxFuel))
	
	var warning = perc <= PlayerStats.fuelPercentageWarning
	
	if warning != fuelWarning:
		fuelWarning = warning
		fuelWarningAnim.stop()
		if warning:
			fuelWarningAnim.play("Anim")
		else:
			fuelWarningAnim.play("Anim", -1, -1, true)
	
	debug(delta)

func debug(delta: float) -> void:
	var text : PoolStringArray = PoolStringArray()
	var fps = 1.0 / delta
	showFps = lerp(showFps, fps, delta * 4.0)
	text.append("FPS: " + str(round(showFps)))
	if !world.generating:
		text.append("Player State: " + world.player.GetCurrentState().name)
		text.append("Player Speed: " + str(world.player.linear_velocity.length()))
		text.append("Player Angle: " + str(abs(world.player.rotation_degrees)))
	text.append("")
	text.append("Perfects Streak: " + str(PlayerStats.perfectsStreak))
	text.append("Fuel: " + str(ceil(PlayerStats.fuel)) + "/" + str(ceil(PlayerStats.maxFuel)))
	
	debug.text = PoolStringArray(text).join("\n")

func OnWorldGenerated() -> void:
	pass









