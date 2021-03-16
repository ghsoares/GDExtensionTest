extends CanvasLayer

var animating = false

onready var anim := $Anim

func Animate(animOut: bool = false) -> void:
	if animating: return
	animating = true
	
	if animOut:
		anim.play("out")
	else:
		anim.play("in")
	
	yield(anim, "animation_finished")
	
	animating = false
