extends Node

"""
This class records the game actions to be played back automatically (a kind of TAS)
"""

class RecordingData:
	extends Resource
	
	var sessionData: Dictionary
	var data: Dictionary
	var recordedFrames: Array
	
	var dataSize: int = 0
	
	func _init() -> void:
		data = {}
		sessionData = {}

enum Mode {
	None,
	Recording,
	Playback
}

var actions = [
	"thruster_add",
	"thruster_subtract",
	"turn_left",
	"turn_right",
	"reset_level",
	"next_level",
	"slowmo",
]

var currentInputData: Dictionary

var recordingData: RecordingData
var currentFrame := 0
var nextFrame := 0
var nextFrameIdx := 0
var paused: bool
var mode: int= Mode.None
var saveLocation: String= "res://InputRecordings/session0.inprec"

func _ready() -> void:
	if mode == Mode.Recording:
		recordingData = RecordingData.new()
	elif mode == Mode.Playback:
		LoadFromFile()
	paused = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_QUIT_REQUEST:
		if mode == Mode.Recording:
			SaveToFile()

func SaveToFile() -> void:
	var file : File = File.new()
	var err = file.open(saveLocation, File.WRITE)
	if err != OK:
		push_error("[InputRecorder] [Save] Open file error status: " + str(err))
		return
	var finalData = {
		"sessionData": recordingData.sessionData,
		"recordingData": recordingData.data
	}
	print("[InputRecorder] [Save] Saving recording...")
	file.store_var(finalData)
	file.close()
	print("[InputRecorder] [Save] Recording saved to: " + saveLocation)

func LoadFromFile() -> void:
	var file : File = File.new()
	var err = file.open(saveLocation, File.READ)
	if err != OK:
		push_error("[InputRecorder] [Load] Open file error status: " + str(err))
		return
	var data = file.get_var() as Dictionary
	if !data:
		push_warning("[InputRecorder] [Load] Recording data is null, the file can be corrupted")
		file.close()
		return
	print("[InputRecorder] [Load] Loading data...")
	recordingData = RecordingData.new()
	recordingData.sessionData = data["sessionData"]
	recordingData.data = data["recordingData"]
	recordingData.dataSize = recordingData.data.size()
	recordingData.recordedFrames = recordingData.data.keys()
	print("[InputRecorder] [Load] Data loaded!")
	print("[InputRecorder] [Load] Session Data: \n" + str(recordingData.sessionData))
	print("[InputRecorder] [Load] Recording Data Size: " + str(recordingData.dataSize))
	print("[InputRecorder] [Load] Recorded Frames: " + str(recordingData.recordedFrames))

func GetSessionData(key: String, default = null, writeDefault = true):
	if recordingData == null:
		return default
	if !recordingData.sessionData.has(key) and writeDefault:
		recordingData.sessionData[key] = default
	return recordingData.sessionData.get(key, default)

func Pause():
	print("[InputRecorder] Recording paused")
	paused = true

func Resume():
	print("[InputRecorder] Recording resumed")
	paused = false

func _physics_process(delta: float) -> void:
	if paused: return
	match mode:
		Mode.Recording:
			RecordProcess(delta)
			pass
		Mode.Playback:
			PlaybackProcess(delta)
			pass

func RecordProcess(delta: float) -> void:
	var changedInputData = {}
	
	if !currentInputData:
		for action in actions:
			var thisActionPressed = Input.is_action_pressed(action)
			var thisActionStrength = Input.get_action_strength(action)
			
			changedInputData[action] = {}
			currentInputData[action] = {}
			
			changedInputData[action]["pressed"] = thisActionPressed
			changedInputData[action]["strength"] = thisActionStrength
			
			currentInputData[action]["pressed"] = thisActionPressed
			currentInputData[action]["strength"] = thisActionStrength
	else:
		for action in actions:
			var thisActionPressed = Input.is_action_pressed(action)
			var thisActionStrength = Input.get_action_strength(action)
			
			if currentInputData[action].pressed != thisActionPressed:
				changedInputData[action] = {}
				changedInputData[action]["pressed"] = thisActionPressed
				currentInputData[action]["pressed"] = thisActionPressed
			
			if currentInputData[action].strength != thisActionStrength:
				changedInputData[action] = changedInputData.get(action, {})
				changedInputData[action]["strength"] = thisActionStrength
				currentInputData[action]["strength"] = thisActionStrength
	
	if !changedInputData.empty():
		var frameData = {
			"actions": changedInputData,
			"frame": currentFrame
		}
		recordingData.data[currentFrame] = frameData
	
	currentFrame += 1

func PlaybackProcess(delta: float) -> void:
	if currentFrame == nextFrame:
		var frameData = recordingData.data[currentFrame]
		var actionsData = frameData["actions"]
		
		if !currentInputData:
			currentInputData = frameData
		
		for action in actionsData.keys():
			var pressed = actionsData[action].get("pressed", currentInputData["actions"][action]["pressed"])
			var strength = actionsData[action].get("strength", currentInputData["actions"][action]["strength"])
			
			if pressed:
				Input.action_press(action, strength)
			else:
				Input.action_release(action)
			
			currentInputData["actions"][action]["pressed"] = pressed
			currentInputData["actions"][action]["strength"] = strength
		
		nextFrameIdx += 1
		
		if nextFrameIdx == recordingData.dataSize:
			print("[InputRecorder] [Playback] Playback finished")
			mode = Mode.None
			return
		
		nextFrame = recordingData.recordedFrames[nextFrameIdx]
	
	currentFrame += 1
