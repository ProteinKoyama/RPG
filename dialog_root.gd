extends CanvasLayer

var duration: float = 0.05
var tmp_branch := 0

@onready var name_label := $Textbox/Name
@onready var dialog_label := $Textbox/Dialog
@onready var ingame_menu := $Textbox/IngameMenu
@onready var menu_conatainer := $Textbox/VBoxContainer
@onready var textbox := $Textbox

var dialog: Array = []
var dialog_index := 0
var ignore_opening_input := true

signal dialog_finished(result)

func _ready():
	textbox.hide()
	ingame_menu.hide()

func setup(dialog_data):
	print("dialog setup called")
	dialog = dialog_data
	dialog_index = 0
	tmp_branch = 0
	ignore_opening_input = true
	textbox.show()
	_show_current_line()
	await get_tree().process_frame
	ignore_opening_input = false

func _show_current_line():
	if dialog.is_empty():
		return
	if dialog_index < 0 or dialog_index >= dialog.size():
		return

	var line = dialog[dialog_index]

	if line[0] == "CallMenuCommand":
		_show_call_menu(line[1])
		return

	if line[0] == "BranchCommand":
		_show_branch_line(line[1][tmp_branch])
		return

	name_label.text = line[0]
	dialog_label.text = line[1]
	dialog_label.visible_ratio = 0

func _show_call_menu(items):
	ingame_menu.show()

	for child in menu_conatainer.get_children():
		child.queue_free()

	for i in range(items.size()):
		var ingame_menu_button = Button.new()
		ingame_menu_button.add_theme_font_size_override("font_size", 24)
		ingame_menu_button.text = items[i]
		ingame_menu_button.pressed.connect(
			Callable(self, "_on_ingame_menu_button_pressed").bind(i, items[i])
		)
		menu_conatainer.add_child(ingame_menu_button)

func _show_branch_line(branch_data):
	name_label.text = branch_data[0]
	dialog_label.text = branch_data[1]
	dialog_label.visible_ratio = 0

func _process(_delta):
	if dialog_label.text.length() > 0 and dialog_label.visible_ratio < 1:
		dialog_label.visible_ratio += 1.0 / dialog_label.text.length() * (1.0 - duration)

func _unhandled_input(event: InputEvent) -> void:
	if ignore_opening_input:
		return

	if event.is_action_pressed("interact"):
		if event is InputEventKey and event.echo:
			return

		# 文字送り中なら全文表示
		if dialog_label.visible_ratio < 1:
			dialog_label.visible_ratio = 1
		else:
			advance_dialog()

		get_viewport().set_input_as_handled()

func advance_dialog():
	dialog_index += 1

	if dialog_index >= dialog.size():
		EventManager.dialog_closed()
		dialog_finished.emit()
		queue_free()
		return

	# メニュー系コマンドは表示して止める
	if dialog[dialog_index][0] == "CallMenuCommand":
		_show_current_line()
		return

	if dialog[dialog_index][0] == "BranchCommand":
		_show_current_line()
		return

	# 通常会話
	_show_current_line()

func _on_ingame_menu_button_pressed(i, item):
	tmp_branch = i
	ingame_menu.hide()
	dialog_index += 1

	if dialog_index >= dialog.size():
		EventManager.dialog_closed()
		dialog_finished.emit()
		queue_free()
		return

	_show_current_line()

func _exit_tree():
	EventManager.dialog_visible = false
