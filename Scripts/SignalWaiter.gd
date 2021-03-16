class_name SignalWaiter

var yields = 0

signal finished

func _init(var objs: Array, var signals: Array) -> void:
	for i in range(objs.size()):
		wait(objs[i], signals[i])

func wait(var obj, var sig) -> void:
	yields += 1
	yield(obj, sig)
	yields -= 1
	if yields == 0:
		emit_signal("finished")
