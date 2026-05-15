extends Node

var menu_scene: PackedScene = preload("res://menu_scene.tscn")
var menu_instance: Control = null

func is_menu_open() -> bool:
	return menu_instance != null

func open_menu():
	if PlayerManager.in_battle:
		return
	if !PlayerManager.can_move:
		return
	if menu_instance != null:
		return
	PlayerManager.can_move = false
	get_tree().paused = true

	menu_instance = menu_scene.instantiate()

	var ui_layer = get_tree().current_scene.get_node_or_null("UI")
	if ui_layer == null:
		print("UI layer not found")
		menu_instance = null
		PlayerManager.can_move = true
		get_tree().paused = false
		return

	ui_layer.add_child(menu_instance)
	menu_instance.open_menu()

func close_menu():
	if menu_instance == null:
		return

	menu_instance.queue_free()
	menu_instance = null
	get_tree().paused = false
	PlayerManager.can_move = true
