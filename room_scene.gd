extends Node
var DialogScene := preload("res://DialogRoot.tscn")
func _ready() -> void:
	PlayerManager.spawn_player($PlayerSpawnPoint.global_position)
	EventManager.connect("request_show_dialog", Callable(self, "_on_request_show_dialog"))
	
func _process(_delta: float) -> void:
	pass

func _on_area_2d_body_entered(_body: Node2D) -> void:
	GameManager.transition_to_scene("res://scenes/scene1.tscn", "FromMyRoom")


func _on_roma_character_interacted_signal(_body) -> void:
	#EventManager.message()
	if !EventManager.dialog_visible("DialogRoot"): EventManager.show_dialog([])
func _on_request_show_dialog(dialog_data):
	var dialog = DialogScene.instantiate()
	add_child(dialog)
