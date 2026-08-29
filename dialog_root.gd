extends CanvasLayer

var duration: float = 0.05
var tmp_branch := 0

@onready var name_label := $Textbox/Name
@onready var dialog_label := $Textbox/Dialog
@onready var ingame_menu := $IngameMenu
@onready var menu_container := $IngameMenu/MarginContainer/VBoxContainer
@onready var textbox := $Textbox

var dialog: Array = []
var dialog_index := 0
var ignore_opening_input := true
var reveal_elapsed := 0.0
var selected_result := -1
var choice_buttons: Array[Button] = []
var focused_choice_index := 0

signal dialog_finished(result)

func _ready():
	textbox.hide()
	ingame_menu.hide()

func setup(dialog_data):
	print("dialog setup called")
	dialog = dialog_data
	dialog_index = 0
	tmp_branch = 0
	selected_result = -1
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
	_start_text_reveal()

func _show_call_menu(items):
	textbox.hide()
	ingame_menu.show()
	choice_buttons.clear()
	focused_choice_index = 0

	for child in menu_container.get_children():
		child.free()

	for i in range(items.size()):
		var ingame_menu_button = Button.new()
		ingame_menu_button.custom_minimum_size = Vector2(440, 52)
		ingame_menu_button.add_theme_font_size_override("font_size", 30)
		ingame_menu_button.text = items[i]
		ingame_menu_button.focus_mode = Control.FOCUS_ALL
		ingame_menu_button.pressed.connect(
			Callable(self, "_on_ingame_menu_button_pressed").bind(i, items[i])
		)
		menu_container.add_child(ingame_menu_button)
		choice_buttons.append(ingame_menu_button)
	call_deferred("_focus_choice", 0)

func _input(event: InputEvent) -> void:
	if !ingame_menu.visible or choice_buttons.is_empty():
		return
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_down"):
		_focus_choice(focused_choice_index + 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_focus_choice(focused_choice_index - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		choice_buttons[focused_choice_index].pressed.emit()
		get_viewport().set_input_as_handled()

func _focus_choice(index: int) -> void:
	if choice_buttons.is_empty():
		return
	focused_choice_index = posmod(index, choice_buttons.size())
	choice_buttons[focused_choice_index].grab_focus()

func _show_branch_line(branch_data):
	name_label.text = branch_data[0]
	dialog_label.text = branch_data[1]
	_start_text_reveal()

func _start_text_reveal() -> void:
	reveal_elapsed = 0.0
	dialog_label.visible_characters = 0

func _process(delta: float) -> void:
	var text_length: int = dialog_label.text.length()
	if text_length == 0 or dialog_label.visible_characters >= text_length:
		return

	if duration <= 0.0:
		dialog_label.visible_characters = text_length
		return

	reveal_elapsed += delta
	var characters_to_reveal: int = int(reveal_elapsed / duration)
	if characters_to_reveal > 0:
		dialog_label.visible_characters = mini(
			dialog_label.visible_characters + characters_to_reveal,
			text_length
		)
		reveal_elapsed -= characters_to_reveal * duration

func _unhandled_input(event: InputEvent) -> void:
	if ignore_opening_input:
		return
	if ingame_menu.visible:
		return

	if event.is_action_pressed("interact"):
		if event is InputEventKey and event.echo:
			return

		# 文字送り中なら全文表示
		if dialog_label.visible_characters < dialog_label.text.length():
			dialog_label.visible_characters = dialog_label.text.length()
			reveal_elapsed = 0.0
		else:
			advance_dialog()

		get_viewport().set_input_as_handled()

func advance_dialog():
	dialog_index += 1

	if dialog_index >= dialog.size():
		EventManager.dialog_closed()
		dialog_finished.emit(selected_result)
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
	selected_result = i
	ingame_menu.hide()
	choice_buttons.clear()
	dialog_index += 1

	if dialog_index >= dialog.size():
		EventManager.dialog_closed()
		dialog_finished.emit(selected_result)
		queue_free()
		return

	textbox.show()
	_show_current_line()

func _exit_tree():
	EventManager.dialog_visible = false
