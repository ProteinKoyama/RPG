extends Node

func _ready() -> void:
	print("scene1")
	pass
func _process(_delta: float) -> void:
	pass


func _on_to_my_room_area_entered(area: Area2D) -> void:
	if Input.is_action_pressed("interact"):
		GameManager.transition_to_scene("res://scenes/room_scene.tscn", "FromScene1")
