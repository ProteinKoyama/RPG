extends Control

@onready var party_list = $PanelContainer/HBoxContainer/PartyList
@onready var detail_panel = $PanelContainer/HBoxContainer/DetailPanel/Content
@onready var menu_commands = $PanelContainer/HBoxContainer/MenuCommands
@onready var character_list_button = $PanelContainer/HBoxContainer/MenuCommands/CharacterListButton
@onready var item_button = $PanelContainer/HBoxContainer/MenuCommands/ItemButton
@onready var option_button = $PanelContainer/HBoxContainer/MenuCommands/OptionButton

var current_party: Array = []
var selected_member_index := 0
var detail_view := "status"
var current_screen := "top"
var showing_member_detail := false
var equipment_select_slot := ""
var pending_item_id := ""
var last_top_button: Button = null
var equipment_description_label: Label = null
var equipment_preview_list: VBoxContainer = null

func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	character_list_button.pressed.connect(_open_party_screen)
	item_button.pressed.connect(_open_item_screen)
	option_button.pressed.connect(_open_option_screen)

func open_menu():
	current_party = PartyManager.get_party()
	selected_member_index = 0
	detail_view = "status"
	current_screen = "top"
	showing_member_detail = false
	equipment_select_slot = ""
	pending_item_id = ""
	last_top_button = character_list_button
	visible = true
	_update_party_list()
	_show_top_screen()

func close_menu():
	visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel") and current_screen == "item_target_select":
		await _return_to_item_list()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and current_screen == "equipment_select":
		await _return_to_equipment_view()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and showing_member_detail:
		await _return_to_party_list()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and current_screen == "party":
		await _return_to_top_menu()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and current_screen == "items":
		await _return_to_top_menu()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and current_screen == "options":
		await _return_to_top_menu()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("menu"):
		MenuManager.close_menu()
		get_viewport().set_input_as_handled()

func _show_top_screen():
	current_screen = "top"
	showing_member_detail = false
	menu_commands.show()
	party_list.hide()
	detail_panel.show()
	_update_detail_panel(false)
	await get_tree().process_frame
	if last_top_button:
		last_top_button.grab_focus()
	else:
		character_list_button.grab_focus()

func _open_party_screen():
	current_screen = "party"
	showing_member_detail = false
	equipment_select_slot = ""
	pending_item_id = ""
	last_top_button = character_list_button
	menu_commands.hide()
	party_list.show()
	detail_panel.show()
	_update_detail_panel(false)
	await get_tree().process_frame
	if party_list.get_child_count() > 0:
		party_list.get_child(selected_member_index).grab_focus()

func _open_item_screen():
	current_screen = "items"
	showing_member_detail = false
	equipment_select_slot = ""
	pending_item_id = ""
	last_top_button = item_button
	menu_commands.show()
	party_list.hide()
	detail_panel.show()
	_update_inventory_view()
	await get_tree().process_frame
	_grab_first_inventory_button()

func _open_option_screen():
	current_screen = "options"
	showing_member_detail = false
	equipment_select_slot = ""
	pending_item_id = ""
	last_top_button = option_button
	menu_commands.show()
	party_list.hide()
	detail_panel.show()
	_update_option_view()
	await get_tree().process_frame
	var first_slider = _find_first_slider(detail_panel)
	if first_slider:
		first_slider.grab_focus()

func _update_party_list():
	for child in party_list.get_children():
		child.queue_free()

	for i in range(current_party.size()):
		var member = current_party[i]
		var button = Button.new()
		button.text = member.char_name
		button.focus_mode = Control.FOCUS_ALL
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_member_pressed.bind(i))
		party_list.add_child(button)

	await get_tree().process_frame
	if current_screen == "party" and party_list.get_child_count() > 0:
		party_list.get_child(0).grab_focus()

func _update_detail_panel(focus_tab := false):
	for child in detail_panel.get_children():
		child.queue_free()

	if current_party.is_empty():
		var empty_label = Label.new()
		empty_label.text = "パーティメンバーがいません"
		detail_panel.add_child(empty_label)
		return

	selected_member_index = clampi(selected_member_index, 0, current_party.size() - 1)
	if !showing_member_detail:
		_add_all_members_view()
		return

	var member = current_party[selected_member_index]

	var header = Label.new()
	header.text = member.char_name
	detail_panel.add_child(header)

	var tabs = HBoxContainer.new()
	var status_button = Button.new()
	status_button.text = "ステータス"
	status_button.pressed.connect(_set_detail_view.bind("status"))
	var skills_button = Button.new()
	skills_button.text = "特技"
	skills_button.pressed.connect(_set_detail_view.bind("skills"))
	var equipment_button = Button.new()
	equipment_button.text = "装備"
	equipment_button.pressed.connect(_set_detail_view.bind("equipment"))
	tabs.add_child(status_button)
	tabs.add_child(skills_button)
	tabs.add_child(equipment_button)
	detail_panel.add_child(tabs)

	match detail_view:
		"skills":
			_add_skills_view(member)
		"equipment":
			_add_equipment_view(member)
		_:
			_add_status_view(member)

	if focus_tab:
		await get_tree().process_frame
		match detail_view:
			"skills":
				skills_button.grab_focus()
			"equipment":
				equipment_button.grab_focus()
			_:
				status_button.grab_focus()

func _set_detail_view(view_name):
	detail_view = view_name
	await _update_detail_panel(true)

func _add_all_members_view():
	for member in current_party:
		var row = VBoxContainer.new()

		var name = Label.new()
		name.text = member.char_name

		var hp = Label.new()
		hp.text = "HP: %d / %d" % [member.hp, member.max_hp]

		var level = Label.new()
		level.text = "レベル: %d" % member.level

		var sp = Label.new()
		sp.text = "SP: %d / %d" % [member.sp, member.max_sp]

		row.add_child(name)
		row.add_child(level)
		row.add_child(hp)
		row.add_child(sp)

		var frame = _create_padded_panel()
		frame.add_child(row)
		detail_panel.add_child(frame)

func _add_status_view(member):
	var row = VBoxContainer.new()

	var hp = Label.new()
	hp.text = "HP: %d / %d" % [member.hp, member.max_hp]

	var level = Label.new()
	level.text = "レベル: %d" % member.level

	var sp = Label.new()
	sp.text = "SP: %d / %d" % [member.sp, member.max_sp]

	var atk = Label.new()
	atk.text = "攻撃: %d" % member.attack

	var defense = Label.new()
	defense.text = "防御: %d" % member.defense

	var speed = Label.new()
	speed.text = "素早さ: %d" % member.speed

	row.add_child(level)
	row.add_child(hp)
	row.add_child(sp)
	row.add_child(atk)
	row.add_child(defense)
	row.add_child(speed)

	var frame = _create_padded_panel()
	frame.add_child(row)
	detail_panel.add_child(frame)

func _add_skills_view(member):
	var list = VBoxContainer.new()
	var available_skills = member.get_available_skills()
	if available_skills.is_empty():
		var none = Label.new()
		none.text = "特技を覚えていません"
		list.add_child(none)
	else:
		for skill in available_skills:
			var skill_box = VBoxContainer.new()
			var name = Label.new()
			name.text = skill.get("name", "特技")
			var cost = Label.new()
			cost.text = SkillDatabase.get_menu_skill_cost_text(skill)
			var effect = Label.new()
			effect.text = SkillDatabase.get_menu_skill_description(skill)
			skill_box.add_child(name)
			skill_box.add_child(cost)
			skill_box.add_child(effect)
			var frame = _create_padded_panel()
			frame.add_child(skill_box)
			list.add_child(frame)
	detail_panel.add_child(list)

func _add_equipment_view(member):
	var stats = Label.new()
	stats.text = "攻撃: %d  防御: %d  素早さ: %d" % [member.attack, member.defense, member.speed]
	detail_panel.add_child(stats)

	var equipment_area = HBoxContainer.new()
	equipment_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipment_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_child(equipment_area)

	var slot_list = VBoxContainer.new()
	slot_list.custom_minimum_size = Vector2(260, 0)
	equipment_area.add_child(slot_list)

	equipment_preview_list = VBoxContainer.new()
	equipment_preview_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipment_area.add_child(equipment_preview_list)

	equipment_description_label = Label.new()
	equipment_description_label.text = ""
	equipment_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var description_frame = _create_padded_panel()
	description_frame.custom_minimum_size = Vector2(0, 72)
	description_frame.add_child(equipment_description_label)
	detail_panel.add_child(description_frame)

	for slot_id in member.get_equipment_slot_ids():
		var button = Button.new()
		button.focus_mode = Control.FOCUS_ALL
		var item_id = member.get_equipped_item_id(slot_id)
		var item_name = "なし"
		if item_id != "":
			item_name = ItemDatabase.get_item_name(item_id)
		button.text = "%s: %s" % [member.get_equipment_slot_name(slot_id), item_name]
		button.focus_entered.connect(_update_equipment_slot_preview.bind(member, slot_id))
		button.pressed.connect(_open_equipment_select.bind(slot_id))
		slot_list.add_child(button)

	if !member.get_equipment_slot_ids().is_empty():
		_update_equipment_slot_preview(member, member.get_equipment_slot_ids()[0])

func _update_equipment_slot_preview(member, slot_id: String):
	if equipment_preview_list == null or equipment_description_label == null:
		return
	for child in equipment_preview_list.get_children():
		child.queue_free()

	var slot_name = member.get_equipment_slot_name(slot_id)
	var header = Label.new()
	header.text = slot_name + "に装備できるアイテム"
	equipment_preview_list.add_child(header)

	var equipped_item_id = member.get_equipped_item_id(slot_id)
	if equipped_item_id != "":
		equipment_description_label.text = ItemDatabase.get_item_description(equipped_item_id)
	else:
		equipment_description_label.text = slot_name + "には何も装備していません"

	_add_equipment_preview_row("なし", equipped_item_id == "", {})

	var item_ids = InventoryManager.get_equipment_for_slot(slot_id, member.char_id)
	for item_id in item_ids:
		var item = ItemDatabase.get_item_data(item_id)
		_add_equipment_preview_row(item.get("name", item_id), item_id == equipped_item_id, item)

	if item_ids.is_empty():
		var empty = Label.new()
		empty.text = "装備できる所持品がありません"
		equipment_preview_list.add_child(empty)

func _add_equipment_preview_row(item_name: String, equipped: bool, _item: Dictionary):
	var row = HBoxContainer.new()
	var name = Label.new()
	if equipped:
		name.text = item_name + "（装備中）"
	else:
		name.text = item_name
	row.add_child(name)

	var frame = _create_padded_panel()
	frame.add_child(row)
	equipment_preview_list.add_child(frame)

func _update_inventory_view():
	for child in detail_panel.get_children():
		child.queue_free()

	var item_buttons := []
	var header = Label.new()
	header.text = "アイテム"
	detail_panel.add_child(header)

	var inventory = InventoryManager.get_all_items()
	if inventory.is_empty():
		var empty = Label.new()
		empty.text = "アイテムを持っていません"
		detail_panel.add_child(empty)
		return

	for item_id in inventory.keys():
		var item = ItemDatabase.get_item_data(item_id)
		var row = VBoxContainer.new()
		var name
		if InventoryManager.can_use_item(item_id):
			name = Button.new()
			name.focus_mode = Control.FOCUS_ALL
			name.pressed.connect(_open_item_target_select.bind(item_id))
			item_buttons.append(name)
		else:
			name = Label.new()
		name.text = "%s x%d" % [item.get("name", item_id), inventory[item_id]]
		var description = Label.new()
		description.text = ItemDatabase.get_item_description(item_id)
		row.add_child(name)
		row.add_child(description)
		var frame = _create_padded_panel()
		frame.add_child(row)
		detail_panel.add_child(frame)

	_connect_vertical_focus(item_buttons)

func _update_option_view():
	for child in detail_panel.get_children():
		child.queue_free()

	var header = Label.new()
	header.text = "オプション"
	detail_panel.add_child(header)

	_add_volume_slider(
		"全体音量",
		OptionsManager.master_volume,
		_on_master_volume_changed
	)
	_add_volume_slider(
		"BGM音量",
		OptionsManager.bgm_volume,
		_on_bgm_volume_changed
	)
	_add_volume_slider(
		"SE音量",
		OptionsManager.se_volume,
		_on_se_volume_changed
	)

func _add_volume_slider(label_text: String, value: int, callback: Callable):
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label = Label.new()
	label.custom_minimum_size = Vector2(120, 0)
	label.text = label_text
	row.add_child(label)

	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = value
	slider.focus_mode = Control.FOCUS_ALL
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	var value_label = Label.new()
	value_label.custom_minimum_size = Vector2(48, 0)
	value_label.text = str(value)
	row.add_child(value_label)

	slider.value_changed.connect(
		func(new_value):
			value_label.text = str(int(new_value))
			callback.call(int(new_value))
	)

	var frame = _create_padded_panel()
	frame.add_child(row)
	detail_panel.add_child(frame)

func _open_item_target_select(item_id: String):
	pending_item_id = item_id
	var item = ItemDatabase.get_item_data(item_id)
	if item.get("scope", "ally") == "party":
		if InventoryManager.use_item(item_id, current_party):
			_update_party_list()
			await _return_to_item_list()
		return

	current_screen = "item_target_select"
	for child in detail_panel.get_children():
		child.queue_free()

	var header = Label.new()
	header.text = item.get("name", item_id) + "を使う相手"
	detail_panel.add_child(header)

	for i in range(current_party.size()):
		var member = current_party[i]
		var button = Button.new()
		button.focus_mode = Control.FOCUS_ALL
		button.text = "%s  HP %d / %d  SP %d / %d" % [
			member.char_name,
			member.hp,
			member.max_hp,
			member.sp,
			member.max_sp
		]
		button.pressed.connect(_use_pending_item.bind(i))
		detail_panel.add_child(button)

	await get_tree().process_frame
	if detail_panel.get_child_count() > 1:
		detail_panel.get_child(1).grab_focus()

func _use_pending_item(member_index: int):
	if pending_item_id == "":
		return
	if member_index < 0 or member_index >= current_party.size():
		return
	var member = current_party[member_index]
	if InventoryManager.use_item(pending_item_id, member):
		selected_member_index = member_index
		_update_party_list()
		await _return_to_item_list()

func _return_to_item_list():
	current_screen = "items"
	showing_member_detail = false
	equipment_select_slot = ""
	pending_item_id = ""
	party_list.hide()
	menu_commands.show()
	detail_panel.show()
	_update_inventory_view()
	await get_tree().process_frame
	_grab_first_inventory_button()

func _grab_first_inventory_button():
	var button = _find_first_button(detail_panel)
	if button:
		button.grab_focus()
	else:
		item_button.grab_focus()

func _find_first_button(node):
	for child in node.get_children():
		if child is Button:
			return child
		var button = _find_first_button(child)
		if button:
			return button
	return null

func _find_first_slider(node):
	for child in node.get_children():
		if child is HSlider:
			return child
		var slider = _find_first_slider(child)
		if slider:
			return slider
	return null

func _on_master_volume_changed(value: int):
	OptionsManager.set_master_volume(value)

func _on_bgm_volume_changed(value: int):
	OptionsManager.set_bgm_volume(value)

func _on_se_volume_changed(value: int):
	OptionsManager.set_se_volume(value)

func _connect_vertical_focus(buttons: Array):
	for i in range(buttons.size()):
		var button = buttons[i]
		if i > 0:
			button.focus_neighbor_top = buttons[i - 1].get_path()
			button.focus_previous = buttons[i - 1].get_path()
		if i < buttons.size() - 1:
			button.focus_neighbor_bottom = buttons[i + 1].get_path()
			button.focus_next = buttons[i + 1].get_path()

func _open_equipment_select(slot_id: String):
	equipment_select_slot = slot_id
	current_screen = "equipment_select"
	for child in detail_panel.get_children():
		child.queue_free()

	var member = current_party[selected_member_index]
	var header = Label.new()
	header.text = member.get_equipment_slot_name(slot_id) + "を選択"
	detail_panel.add_child(header)

	var unequip_button = Button.new()
	unequip_button.text = "外す"
	unequip_button.focus_mode = Control.FOCUS_ALL
	unequip_button.focus_entered.connect(_set_equipment_select_description.bind("装備を外します"))
	unequip_button.pressed.connect(_equip_selected_item.bind(""))
	detail_panel.add_child(unequip_button)

	var item_ids = InventoryManager.get_equipment_for_slot(slot_id, member.char_id)
	for item_id in item_ids:
		var item = ItemDatabase.get_item_data(item_id)
		var button = Button.new()
		button.focus_mode = Control.FOCUS_ALL
		button.text = _get_equipment_button_text(item)
		button.focus_entered.connect(_set_equipment_select_description.bind(ItemDatabase.get_item_description(item_id)))
		button.pressed.connect(_equip_selected_item.bind(item_id))
		detail_panel.add_child(button)

	equipment_description_label = Label.new()
	equipment_description_label.text = ""
	equipment_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var description_frame = _create_padded_panel()
	description_frame.custom_minimum_size = Vector2(0, 72)
	description_frame.add_child(equipment_description_label)
	detail_panel.add_child(description_frame)

	await get_tree().process_frame
	unequip_button.grab_focus()

func _set_equipment_select_description(text: String):
	if equipment_description_label != null:
		equipment_description_label.text = text

func _get_equipment_button_text(item: Dictionary) -> String:
	var stats_text = _get_equipment_stats_text(item)
	if stats_text == "":
		return item.get("name", "装備")
	return "%s  %s" % [item.get("name", "装備"), stats_text]

func _get_equipment_stats_text(item: Dictionary) -> String:
	var stats = item.get("stats", {})
	var bonuses := []
	if int(stats.get("attack", 0)) != 0:
		bonuses.append(_format_stat_bonus("攻撃", int(stats.get("attack", 0))))
	if int(stats.get("defense", 0)) != 0:
		bonuses.append(_format_stat_bonus("防御", int(stats.get("defense", 0))))
	if int(stats.get("speed", 0)) != 0:
		bonuses.append(_format_stat_bonus("素早さ", int(stats.get("speed", 0))))
	if bonuses.is_empty():
		return ""
	return _join_strings(bonuses, " ")

func _format_stat_bonus(label: String, value: int) -> String:
	if value > 0:
		return "%s+%d" % [label, value]
	return "%s%d" % [label, value]

func _join_strings(values: Array, separator: String) -> String:
	var text := ""
	for i in range(values.size()):
		if i > 0:
			text += separator
		text += str(values[i])
	return text

func _create_padded_panel() -> PanelContainer:
	var frame = PanelContainer.new()
	frame.add_theme_constant_override("margin_left", 10)
	frame.add_theme_constant_override("margin_top", 8)
	frame.add_theme_constant_override("margin_right", 10)
	frame.add_theme_constant_override("margin_bottom", 8)
	return frame

func _equip_selected_item(item_id: String):
	var member = current_party[selected_member_index]
	if item_id != "" and !ItemDatabase.can_character_equip_item(item_id, equipment_select_slot, member.char_id):
		return
	if item_id != "" and !InventoryManager.give_item_to_equipment(item_id):
		return
	var old_item_id = member.equip_item(equipment_select_slot, item_id)
	InventoryManager.take_equipped_item(old_item_id)
	await _return_to_equipment_view()

func _return_to_equipment_view():
	current_screen = "party"
	equipment_select_slot = ""
	showing_member_detail = true
	detail_view = "equipment"
	await _update_detail_panel(true)

func _on_member_pressed(index):
	selected_member_index = index
	detail_view = "status"
	showing_member_detail = true
	await _update_detail_panel(true)

func _return_to_party_list():
	if showing_member_detail:
		showing_member_detail = false
		detail_view = "status"
		_update_detail_panel(false)
	await get_tree().process_frame
	if selected_member_index >= 0 and selected_member_index < party_list.get_child_count():
		party_list.get_child(selected_member_index).grab_focus()

func _return_to_top_menu():
	await _show_top_screen()
