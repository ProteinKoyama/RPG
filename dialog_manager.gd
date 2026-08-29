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
	await show_dialog_by_id(dialog_id)

func show_dialog_by_id(dialog_id: String, variables: Dictionary = {}) -> bool:
	if !dialogs.has(dialog_id):
		push_error("dialog not found: " + dialog_id)
		EventManager.dialog_visible = false
		return false
	var dialog_data = _build_dialog_data(dialogs[dialog_id], variables)
	if dialog_data.is_empty():
		push_error("dialog is empty: " + dialog_id)
		EventManager.dialog_visible = false
		return false
	await show_dialog_data(dialog_data)
	return true

func _build_dialog_data(source, variables: Dictionary) -> Array:
	var result := []
	if !(source is Array):
		return result
	for line in source:
		if line is Array and line.size() >= 2:
			result.append([
				_format_text(str(line[0]), variables),
				_format_text(str(line[1]), variables)
			])
		elif line is Dictionary:
			result.append([
				_format_text(str(line.get("speaker", "")), variables),
				_format_text(str(line.get("message", "")), variables)
			])
	return result

func _format_text(text: String, variables: Dictionary) -> String:
	var formatted := text
	for key in variables:
		formatted = formatted.replace("{" + str(key) + "}", str(variables[key]))
	return formatted

func show_dialog_data(dialog_data: Array):
	var dialog_root = dialog_scene.instantiate()
	EventManager.dialog_visible = true
	get_tree().current_scene.add_child(dialog_root)
	dialog_root.setup(dialog_data)
	return await dialog_root.dialog_finished

func show_choice(prompt_dialog_id: String, choices: Array) -> int:
	if choices.is_empty():
		push_error("choice options are empty")
		return -1
	var dialog_data := []
	if prompt_dialog_id != "":
		if !dialogs.has(prompt_dialog_id):
			push_error("dialog not found: " + prompt_dialog_id)
			return -1
		dialog_data = _build_dialog_data(dialogs[prompt_dialog_id], {})
	var labels := []
	for choice in choices:
		if choice is Dictionary:
			labels.append(str(choice.get("text", "")))
		else:
			labels.append(str(choice))
	dialog_data.append(["CallMenuCommand", labels])
	return int(await show_dialog_data(dialog_data))
