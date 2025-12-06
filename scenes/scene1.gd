extends Node
var event_area_inside = false
var text_index = -1
signal interact
var text_array = ["E:調べる , Z or Space:テキスト送り/決定\nEsc:メニュー/キャンセル",
"ここは病院です"]
func _ready() -> void:
	pass
func _process(_delta: float) -> void:
	if event_area_inside and Input.is_action_just_pressed("interact") and text_index >= 0:
		print(%TalkPanel/Textbox)


func _on_roma_character_interacted_signal() -> void:
	$MessageWindow.visible()
