extends StaticBody2D

signal character_interacted_signal

var interacted_flag = false
var char_in_area_flag = false
var char_body

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if char_in_area_flag:
		if Input.is_action_just_released("interact"):
			#emit_signal("character_interacted_signal",self)
			EventManager.message("test")
func _on_area_2d_body_entered(body: Node2D) -> void:
	char_in_area_flag = true
	char_body = self
func _on_area_2d_body_exited(body: Node2D) -> void:
	char_in_area_flag = false
	char_body = null
