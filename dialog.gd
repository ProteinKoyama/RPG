extends Control

var dialog_index = 0
var finished = false

var dialog = ["Hello","world","!!"]

func _ready():
	load_dialog()
	if Input.is_action_just_pressed("talk"):
		load_dialog()
	
func load_dialog():
	if dialog_index < dialog.size():
		finished = false
		$Label.bbcode_text = dialog[dialog.index]
		$Label.percent.visible = 0
		
