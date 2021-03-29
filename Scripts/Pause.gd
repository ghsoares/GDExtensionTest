extends CanvasLayer

func _ready() -> void:
	get_tree().paused = true

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = !get_tree().paused
