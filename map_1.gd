extends Node

var message_window_flag = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if message_window_flag and Input.is_action_pressed("interact"):
		$MessageWindow.show()
		$MessageWindow/TalkWindow/Label.text = "E:インタラクト , Z or Space:テキスト送り/決定\nX or Esc:メニュー/キャンセル　（予定）"

func _on_event_body_entered(body: Node2D) -> void:
	message_window_flag = true
	
func _on_event_body_exited(body: Node2D) -> void:
	message_window_flag = false
