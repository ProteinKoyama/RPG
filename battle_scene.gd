extends Node

@onready var battle_dialog := $UI/MessageWindow/Label
@onready var main_commands := $UI/MainCommands
@onready var fight_button := $UI/MainCommands/FightButton
@onready var escape_button := $UI/MainCommands/EscapeButton
@onready var party_container = $UI/CommandWindow/PartyContainer
@onready var color_rect = $UI/ColorRect
@onready var enemy_area = $UI/EnemyArea
@onready var skill_window = $UI/SkillWindow
@onready var skill_list = $UI/SkillWindow/SkillList
@onready var description_panel = $UI/DescriptionPanel
@onready var description_label = $UI/DescriptionPanel/DescriptionLabel
@onready var bgm_player = $BGMPlayer

var EnemyStatusScene = preload("res://enemy_status.tscn")
var PartyStatusScene = preload("res://party_status.tscn")

signal main_command_selected(command)
signal member_action_selected(index, action)
signal cancel_requested
signal enemy_target_selected(enemy)
signal skill_selected(skill)
signal item_selected(item_id)
signal party_target_selected(index)

var messages = []
var target_select_active := false
var target_enemy_index := 0
var target_select_wait_accept_release := false
var party_target_select_active := false
var party_target_index := 0
var party_target_wait_accept_release := false
var main_command_active := false
var main_command_locked := false
var skill_select_active := false
var escape_enabled := true
var previous_bgm_player: AudioStreamPlayer = null
var previous_bgm_was_playing := false

func _ready() -> void:
	add_to_group("battle_scenes")
	print("battle scene created")
	print("focus owner:", get_viewport().gui_get_focus_owner())

	fight_button.focus_mode = Control.FOCUS_ALL
	_apply_escape_enabled()

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
	party_target_select_active = false
	skill_select_active = false
	_hide_action_description()
	skill_window.hide()
	disable_all_commands()
	main_commands.visible = true
	color_rect.show()
	main_commands.show()
	_apply_escape_enabled()
	await get_tree().process_frame
	fight_button.grab_focus()

func show_action_commands():
	main_command_active = false
	main_command_locked = false
	skill_select_active = false
	_hide_action_description()
	skill_window.hide()
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
	if skill_select_active:
		if event.is_action_pressed("ui_cancel"):
			cancel_requested.emit()
			get_viewport().set_input_as_handled()
		return

	if party_target_select_active:
		if party_target_wait_accept_release:
			if event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
			return

		if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
			_focus_party_target(party_target_index + 1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
			_focus_party_target(party_target_index - 1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			_confirm_party_target()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel"):
			cancel_requested.emit()
			get_viewport().set_input_as_handled()
		return

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
		if escape_enabled:
			escape_button.grab_focus()
		else:
			fight_button.grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		fight_button.grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		var focus_owner = get_viewport().gui_get_focus_owner()
		if focus_owner == escape_button and escape_enabled:
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
	party_target_select_active = false
	party_target_wait_accept_release = false
	skill_select_active = false
	_hide_action_description()
	stop_battle_bgm()
	set_process_input(false)
	set_process_unhandled_input(false)
	get_viewport().gui_release_focus()
	if has_node("UI"):
		$UI.visible = false
	queue_free()

func set_escape_enabled(enabled: bool):
	escape_enabled = enabled
	_apply_escape_enabled()

func _apply_escape_enabled():
	if fight_button == null or escape_button == null:
		return
	escape_button.disabled = !escape_enabled
	escape_button.focus_mode = Control.FOCUS_ALL if escape_enabled else Control.FOCUS_NONE
	if escape_enabled:
		fight_button.focus_neighbor_bottom = escape_button.get_path()
		fight_button.focus_next = escape_button.get_path()
		escape_button.focus_neighbor_top = fight_button.get_path()
		escape_button.focus_previous = fight_button.get_path()
	else:
		fight_button.focus_neighbor_bottom = fight_button.get_path()
		fight_button.focus_next = fight_button.get_path()
		escape_button.focus_neighbor_top = NodePath("")
		escape_button.focus_previous = NodePath("")

func play_battle_bgm(path: String):
	if path == "":
		return
	var stream = load(path)
	if stream == null:
		print("battle bgm not found:", path)
		return
	_pause_map_bgm()
	bgm_player.stream = stream
	bgm_player.play()

func stop_battle_bgm():
	if bgm_player != null:
		bgm_player.stop()
	_resume_map_bgm()

func _pause_map_bgm():
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return
	var map_bgm_player = current_scene.get_node_or_null("BGMPlayer")
	if map_bgm_player == null or map_bgm_player == bgm_player:
		return
	previous_bgm_player = map_bgm_player
	previous_bgm_was_playing = previous_bgm_player.playing
	if previous_bgm_was_playing:
		previous_bgm_player.stream_paused = true

func _resume_map_bgm():
	if previous_bgm_player == null:
		return
	if is_instance_valid(previous_bgm_player) and previous_bgm_was_playing:
		previous_bgm_player.stream_paused = false
	previous_bgm_player = null
	previous_bgm_was_playing = false

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
	skill_select_active = false
	_hide_action_description()
	skill_window.hide()
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

func start_party_target_select(start_index := 0):
	party_target_select_active = true
	party_target_wait_accept_release = true
	target_select_active = false
	skill_select_active = false
	_hide_action_description()
	skill_window.hide()
	main_command_active = false
	party_target_index = start_index
	main_commands.hide()
	disable_all_commands()
	for child in party_container.get_children():
		if child.has_method("enable_target_select"):
			child.enable_target_select()
	connect_party_target_focus()
	_focus_party_target(start_index)
	get_viewport().set_input_as_handled()
	await get_tree().process_frame
	party_target_wait_accept_release = false

func stop_party_target_select():
	party_target_select_active = false
	party_target_wait_accept_release = false
	for child in party_container.get_children():
		if child.has_method("disable_target_select"):
			child.disable_target_select()

func show_skill_select(skills: Array, current_sp: int, current_hp: int):
	disable_all_commands()
	main_commands.hide()
	skill_select_active = true
	skill_window.show()
	_show_action_description("")
	for child in skill_list.get_children():
		child.queue_free()
	await get_tree().process_frame
	for skill in skills:
		var button := Button.new()
		var sp_cost = skill.get("sp_cost", 0)
		var hp_cost = skill.get("hp_cost", 0)
		var can_use = current_sp >= sp_cost and current_hp >= hp_cost
		var cost_text = _get_skill_cost_text(skill)
		button.text = skill.get("name", "特技")
		if cost_text != "":
			button.text += " " + cost_text
		button.focus_mode = Control.FOCUS_ALL
		if !can_use:
			button.modulate = Color(0.65, 0.65, 0.65)
		button.focus_entered.connect(_show_action_description.bind(_get_battle_skill_description(skill)))
		button.pressed.connect(_on_skill_button_selected.bind(skill, can_use))
		skill_list.add_child(button)
	await get_tree().process_frame
	var first_button = _get_first_enabled_button(skill_list)
	if first_button:
		first_button.grab_focus()

func show_item_select(items: Dictionary):
	disable_all_commands()
	main_commands.hide()
	skill_select_active = true
	skill_window.show()
	_show_action_description("")
	for child in skill_list.get_children():
		child.queue_free()
	await get_tree().process_frame
	var item_database = _get_item_database()
	for item_id in items.keys():
		var item = {}
		if item_database != null:
			item = item_database.get_item_data(item_id)
		var button := Button.new()
		button.text = item.get("name", item_id) + " x" + str(items[item_id])
		button.focus_mode = Control.FOCUS_ALL
		button.focus_entered.connect(_show_action_description.bind(item.get("description", "")))
		button.pressed.connect(_on_item_button_selected.bind(item_id))
		skill_list.add_child(button)
	await get_tree().process_frame
	var first_button = _get_first_enabled_button(skill_list)
	if first_button:
		first_button.grab_focus()

func hide_skill_select():
	skill_select_active = false
	skill_window.hide()
	_hide_action_description()
	for child in skill_list.get_children():
		child.queue_free()

func _on_skill_button_selected(skill, can_use := true):
	if !can_use:
		return
	hide_skill_select()
	skill_selected.emit(skill)

func _on_item_button_selected(item_id):
	hide_skill_select()
	item_selected.emit(item_id)

func _get_item_database():
	var tree = Engine.get_main_loop()
	if !(tree is SceneTree):
		return null
	return tree.root.get_node_or_null("ItemDatabase")

func _get_skill_database():
	var tree = Engine.get_main_loop()
	if !(tree is SceneTree):
		return null
	return tree.root.get_node_or_null("SkillDatabase")

func _show_action_description(text: String):
	description_label.text = text
	description_panel.show()

func _hide_action_description():
	description_label.text = ""
	description_panel.hide()

func _get_skill_cost_text(skill: Dictionary) -> String:
	var skill_database = _get_skill_database()
	if skill_database != null:
		return skill_database.get_skill_cost_text(skill)
	return ""

func _get_battle_skill_description(skill: Dictionary) -> String:
	var skill_database = _get_skill_database()
	if skill_database != null:
		return skill_database.get_battle_skill_description(skill)
	return skill.get("name", "特技")

func _join_strings(values: Array, separator: String) -> String:
	var text := ""
	for i in range(values.size()):
		if i > 0:
			text += separator
		text += str(values[i])
	return text

func _format_power(power: float) -> String:
	if is_equal_approx(power, round(power)):
		return str(int(round(power)))
	return "%.1f" % power

func _get_first_enabled_button(parent):
	for child in parent.get_children():
		if child is Button and !child.disabled:
			return child
	return null

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

func _get_selectable_party_nodes():
	var selectable_party = []
	for member_status in party_container.get_children():
		if member_status.has_method("enable_target_select") and member_status.member_ref != null:
			selectable_party.append(member_status)
	return selectable_party

func _focus_party_target(index):
	var members = _get_selectable_party_nodes()
	if members.is_empty():
		return
	party_target_index = posmod(index, members.size())
	members[party_target_index].grab_focus()

func _confirm_party_target():
	var members = _get_selectable_party_nodes()
	if members.is_empty():
		return
	party_target_index = clampi(party_target_index, 0, members.size() - 1)
	party_target_selected.emit(members[party_target_index].member_index)

func connect_party_target_focus():
	var member_nodes = party_container.get_children()
	for i in range(member_nodes.size()):
		var member = member_nodes[i]
		member.focus_mode = Control.FOCUS_ALL
		member.focus_neighbor_left = NodePath("")
		member.focus_neighbor_right = NodePath("")
		member.focus_neighbor_top = NodePath("")
		member.focus_neighbor_bottom = NodePath("")
		if i > 0:
			member.focus_neighbor_left = member_nodes[i - 1].get_path()
			member.focus_neighbor_top = member_nodes[i - 1].get_path()
		if i < member_nodes.size() - 1:
			member.focus_neighbor_right = member_nodes[i + 1].get_path()
			member.focus_neighbor_bottom = member_nodes[i + 1].get_path()

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

func refresh_enemy_status_ui():
	for enemy_ui in enemy_area.get_children():
		if enemy_ui.has_method("refresh_effects"):
			enemy_ui.refresh_effects()

func _on_fight_button_pressed() -> void:
	_select_main_command("fight")

func _on_escape_button_pressed() -> void:
	if !escape_enabled:
		return
	_select_main_command("escape")

func _select_main_command(command):
	if not main_command_active or main_command_locked:
		return
	if command == "escape" and !escape_enabled:
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
