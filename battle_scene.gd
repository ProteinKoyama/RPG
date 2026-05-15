extends Node

@onready var battle_dialog := $UI/MessageWindow/Label
@onready var main_commands := $UI/MainCommands
@onready var fight_button := $UI/MainCommands/FightButton
@onready var escape_button := $UI/MainCommands/EscapeButton
@onready var party_container = $UI/CommandWindow/PartyContainer
@onready var color_rect = $UI/ColorRect
@onready var enemy_area = $UI/EnemyArea

var EnemyStatusScene = preload("res://enemy_status.tscn")
var PartyStatusScene = preload("res://party_status.tscn")

signal main_command_selected(command)
signal member_action_selected(index, action)
signal cancel_requested
signal enemy_target_selected(enemy)

var messages = BattleManager.messages
var target_select_active := false
var target_enemy_index := 0
var target_select_wait_accept_release := false
var main_command_active := false
var main_command_locked := false

func _ready() -> void:
	add_to_group("battle_scenes")
	print("battle scene created")
	print("focus owner:", get_viewport().gui_get_focus_owner())

	fight_button.focus_mode = Control.FOCUS_ALL
	escape_button.focus_mode = Control.FOCUS_ALL
	fight_button.focus_neighbor_bottom = escape_button.get_path()
	escape_button.focus_neighbor_top = fight_button.get_path()
	fight_button.focus_next = escape_button.get_path()
	escape_button.focus_previous = fight_button.get_path()

	if not fight_button.pressed.is_connected(_on_fight_button_pressed):
		fight_button.pressed.connect(_on_fight_button_pressed)
	if not escape_button.pressed.is_connected(_on_escape_button_pressed):
		escape_button.pressed.connect(_on_escape_button_pressed)

	await get_tree().process_frame
	fight_button.grab_focus()

func show_message(message):
	print(message)
	battle_dialog.text = message
	await get_tree().create_timer(1.0).timeout

func show_main_commands():
	main_command_active = true
	main_command_locked = false
	target_select_active = false
	disable_all_commands()
	main_commands.visible = true
	color_rect.show()
	main_commands.show()
	await get_tree().process_frame
	fight_button.grab_focus()

func show_action_commands():
	main_command_active = false
	main_command_locked = false
	print("show action")
	main_commands.visible = false
	color_rect.hide()

func set_active_member(index):
	for i in range(party_container.get_child_count()):
		var status = party_container.get_child(i)
		var enabled = i == index
		status.set_command_enabled(enabled)
		if enabled:
			await status.grab_first_button()

func disable_all_commands():
	for status in party_container.get_children():
		status.set_command_enabled(false)

func focus_party_command(index):
	for i in range(party_container.get_child_count()):
		var status = party_container.get_child(i)
		status.set_command_enabled(i == index)
	await get_tree().process_frame
	var current = party_container.get_child(index)
	await current.grab_first_button()

func _input(event):
	if target_select_active:
		if target_select_wait_accept_release:
			if event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
			return

		if event.is_action_pressed("ui_right"):
			_focus_target_enemy(target_enemy_index + 1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_left"):
			_focus_target_enemy(target_enemy_index - 1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			_confirm_target_enemy()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel"):
			cancel_requested.emit()
			get_viewport().set_input_as_handled()
		return

	if not main_command_active:
		return

	if event.is_action_pressed("ui_down"):
		escape_button.grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		fight_button.grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		var focus_owner = get_viewport().gui_get_focus_owner()
		if focus_owner == escape_button:
			_select_main_command("escape")
		else:
			_select_main_command("fight")
		get_viewport().set_input_as_handled()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		cancel_requested.emit()

func close_scene():
	main_command_active = false
	main_command_locked = true
	target_select_active = false
	target_select_wait_accept_release = false
	set_process_input(false)
	set_process_unhandled_input(false)
	get_viewport().gui_release_focus()
	if has_node("UI"):
		$UI.visible = false
	queue_free()

func update_party_ui(party):
	for child in party_container.get_children():
		child.free()

	for i in range(party.size()):
		var member = party[i]
		var status_ui = PartyStatusScene.instantiate()
		party_container.add_child(status_ui)
		status_ui.setup(member, i)
		if not status_ui.member_action_selected.is_connected(_on_member_action_selected):
			status_ui.member_action_selected.connect(_on_member_action_selected)
	await get_tree().process_frame

func update_enemy_ui(enemies):
	for child in enemy_area.get_children():
		child.queue_free()
	await get_tree().process_frame
	var center_x = enemy_area.size.x / 2
	var center_y = enemy_area.size.y / 2
	var spacing = 240
	for i in range(enemies.size()):
		var enemy = enemies[i]
		var enemy_ui = EnemyStatusScene.instantiate()
		enemy_area.add_child(enemy_ui)
		enemy_ui.setup(enemy)
		enemy_ui.target_selected.connect(_on_enemy_target_selected)
		await get_tree().process_frame
		var offset = get_enemy_offset(i, spacing)
		enemy_ui.position = Vector2(
			center_x + offset - enemy_ui.size.x / 2,
			center_y - enemy_ui.size.y / 2
		)
	connect_enemy_focus()

func get_enemy_offset(index, spacing):
	if index == 0:
		return 0
	var side = 1
	if index % 2 == 0:
		side = -1
	var step = int((index + 1) / 2)
	return spacing * step * side

func start_target_select():
	target_select_active = true
	target_select_wait_accept_release = true
	main_command_active = false
	target_enemy_index = 0
	main_commands.hide()
	disable_all_commands()
	for child in enemy_area.get_children():
		if child.has_method("enable_target_select"):
			child.enable_target_select()
	connect_enemy_focus()
	_focus_target_enemy(0)
	get_viewport().set_input_as_handled()
	await get_tree().process_frame
	target_select_wait_accept_release = false

func stop_target_select():
	target_select_active = false
	target_select_wait_accept_release = false
	for child in enemy_area.get_children():
		if child.has_method("disable_target_select"):
			child.disable_target_select()

func _get_selectable_enemy_nodes():
	var selectable_enemies = []
	for enemy in enemy_area.get_children():
		if enemy.has_method("enable_target_select") and enemy.enemy_ref != null and enemy.enemy_ref.is_alive():
			selectable_enemies.append(enemy)
	return selectable_enemies

func _focus_target_enemy(index):
	var enemies = _get_selectable_enemy_nodes()
	if enemies.is_empty():
		return
	target_enemy_index = posmod(index, enemies.size())
	enemies[target_enemy_index].grab_focus()

func _confirm_target_enemy():
	var enemies = _get_selectable_enemy_nodes()
	if enemies.is_empty():
		return
	target_enemy_index = clampi(target_enemy_index, 0, enemies.size() - 1)
	enemy_target_selected.emit(enemies[target_enemy_index].enemy_ref)

func connect_enemy_focus():
	var enemy_nodes = enemy_area.get_children()
	for i in range(enemy_nodes.size()):
		var enemy = enemy_nodes[i]
		enemy.focus_mode = Control.FOCUS_ALL
		enemy.focus_neighbor_left = NodePath("")
		enemy.focus_neighbor_right = NodePath("")
		if i > 0:
			enemy.focus_neighbor_left = enemy_nodes[i - 1].get_path()
		if i < enemy_nodes.size() - 1:
			enemy.focus_neighbor_right = enemy_nodes[i + 1].get_path()
		print(
			enemy.name,
			enemy.focus_neighbor_left,
			enemy.focus_neighbor_right
		)

func remove_dead_enemies():
	for enemy_ui in enemy_area.get_children():
		if !enemy_ui.enemy_ref.is_alive():
			await enemy_ui.play_death_animation()
	await get_tree().process_frame
	connect_enemy_focus()

func _on_fight_button_pressed() -> void:
	_select_main_command("fight")

func _on_escape_button_pressed() -> void:
	_select_main_command("escape")

func _select_main_command(command):
	if not main_command_active or main_command_locked:
		return
	main_command_locked = true
	main_command_active = false
	main_commands.hide()
	color_rect.hide()
	main_command_selected.emit(command)
	print(command)

func _on_attack_button_pressed() -> void:
	pass

func _on_battle_finished() -> void:
	print("battle finished")

func _on_member_action_selected(index, action):
	member_action_selected.emit(index, action)

func _on_enemy_target_selected(enemy):
	enemy_target_selected.emit(enemy)
