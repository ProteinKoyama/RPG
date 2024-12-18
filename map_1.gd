extends Node

var message_window_flag = false
var text_index
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var text_array = ["E:インタラクト , Z or Space:テキスト送り/決定\nX or Esc:メニュー/キャンセル",
"ここは病院です"]

func _process(delta: float) -> void:
	if message_window_flag and Input.is_action_just_pressed("interact"):
		%MessageWindow/TalkWindow/Label.text = text_array[text_index]
func _on_event_body_entered(body: Node2D) -> void:
	message_window_flag = true
	text_index = 0
func _on_event_body_exited(body: Node2D) -> void:
	message_window_flag = false


func _on_event_1_body_entered(body: Node2D) -> void:
	message_window_flag = true
	text_index = 1

func _on_event_2_body_exited(body: Node2D) -> void:
	message_window_flag = false
