extends Node

var dialogs = {}
var dialog_scene := preload("res://DialogRoot.tscn")

func _ready():
	load_dialog_database()
	EventManager.request_show_dialog.connect(_on_request_show_dialog)

func load_dialog_database():
	var file = FileAccess.open("res://data/dialogs.json", FileAccess.READ)
	if file == null:
		print("dialogs.json open failed")
		return
	dialogs = JSON.parse_string(file.get_as_text())
func _on_request_show_dialog(dialog_id: String) -> void:
	if !dialogs.has(dialog_id):
		print("dialog not found:", dialog_id)
		EventManager.dialog_visible = false
		return
	var dialog_data = dialogs[dialog_id]
	await show_dialog_data(dialog_data)

func show_dialog_data(dialog_data: Array):
	var dialog_root = dialog_scene.instantiate()
	get_tree().current_scene.add_child(dialog_root)
	dialog_root.setup(dialog_data)
	await  dialog_root.dialog_finished
