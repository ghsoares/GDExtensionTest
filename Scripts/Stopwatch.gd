class_name Stopwatch

var prevTick
var label

func _init(label: String) -> void:
	prevTick = OS.get_ticks_msec()
	self.label = label

func Mark() -> void:
	var curr = OS.get_ticks_msec()
	var elapsed = curr - prevTick
	
	print("[StopWatch]" + label + ": " + str(elapsed) + " Msec")
	
	prevTick = curr
