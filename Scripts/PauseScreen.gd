extends CanvasLayer

func _process(delta: float) -> void:
	if Transition.animating:
		get_tree().paused = false
	if Input.is_action_just_pressed("pause") and !Transition.animating:
		get_tree().paused = !get_tree().paused
	
	$Screen.visible = get_tree().paused
