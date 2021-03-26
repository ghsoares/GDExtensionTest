extends CanvasLayer

signal FadeFinished

onready var anim := $Anim

func _ready() -> void:
	anim.connect("animation_finished", self, "OnAnimationFinished")

func FadeIn() -> void:
	anim.stop()
	anim.play("Fade")

func FadeOut() -> void:
	anim.stop()
	anim.play("Fade", -1, -1.0, true)

func OnAnimationFinished(animName: String) -> void:
	emit_signal("FadeFinished")

