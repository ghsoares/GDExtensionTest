tool
extends TextureRect

export (String) var savePath = "res://img.png"
export (bool) var invert
export (bool) var save setget SetSave

func SetSave(_s) -> void:
	var data = texture.get_data()
	if invert:
		data.flip_y()
	print("Save Code: " + str(data.save_png(savePath)))







