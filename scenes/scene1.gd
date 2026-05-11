extends Node
var DialogScene := preload("res://DialogRoot.tscn")
var entered = false
func _ready() -> void:
	
	EventManager.connect("request_show_dialog", Callable(self, "_on_request_show_dialog"))
	pass
func _process(_delta: float) -> void:
	pass
	if Input.is_action_pressed("interact") && entered:
		GameManager.transition_to_scene("res://scenes/room_scene.tscn", "FromScene1")
		entered = false
func _on_to_my_room_body_entered(_body: Node2D) -> void:
	entered = true

func _on_to_my_room_body_exited(_body: Node2D) -> void:
	entered = false

var interacting = false
func _on_roma_character_interacted_signal(_body) -> void:
	if interacting and !EventManager.dialog_visible:
		interacting = false
		return
	if interacting:
		return
	interacting = true
	if !EventManager.dialog_visible:
		print("showdialog")
		EventManager.show_dialog([["roma","test"]])
func _on_request_show_dialog(dialog_data):
	EventManager.dialog_manager_data = dialog_data
	var dialog = DialogScene.instantiate()
	add_child(dialog)
