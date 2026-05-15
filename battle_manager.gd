extends Node

signal battle_finished(battle_result)

enum BattleState {
	MAIN_COMMAND,
	ACTION_SELECT,
	TARGET_SELECT,
	EXECUTE_TURN,
	END
}

var party = []
var enemies = []
var battle_scene = null
var messages = []
var battle_result: String
var state = BattleState.MAIN_COMMAND
var selected_main_command = ""
var current_member_index = 0
var selected_actions = []
var pending_action = ""
var pending_member_index = 0

func _ready() -> void:
	EventManager.battle_requested.connect(_on_battle_requested)

func start_battle(enemy_ids: Array):
	if battle_scene != null or !get_tree().get_nodes_in_group("battle_scenes").is_empty():
		print("start_battle ignored: battle scene already exists")
		return
	PlayerManager.in_battle = true
	var scene = preload("res://BattleScene.tscn")
	battle_scene = scene.instantiate()
	battle_scene.member_action_selected.connect(_on_member_action_selected)
	battle_scene.main_command_selected.connect(_on_main_command_selected)
	battle_scene.cancel_requested.connect(_on_cancel_requested)
	battle_scene.enemy_target_selected.connect(_on_enemy_target_selected)
	get_tree().current_scene.add_child(battle_scene)

	party = PartyManager.get_party()
	await battle_scene.update_party_ui(party)

	enemies.clear()
	for enemy_id in enemy_ids:
		var enemy_data = EnemyDatabase.get_enemy_data(enemy_id)
		var enemy = Character.new(enemy_data)
		enemies.append(enemy)

	await battle_scene.update_enemy_ui(enemies)
	state = BattleState.MAIN_COMMAND
	await battle_scene.show_main_commands()

func handle_main_command(action):
	match action:
		"fight":
			state = BattleState.ACTION_SELECT
			battle_scene.show_action_commands()
			await get_tree().process_frame
			await begin_command_select()
		"escape":
			state = BattleState.END
			end_battle("escape")

func begin_command_select():
	selected_actions.clear()
	current_member_index = 0
	current_member_index = get_next_alive_party_index(current_member_index)
	if current_member_index == -1:
		state = BattleState.EXECUTE_TURN
		await execute_turn()
		return
	await battle_scene.focus_party_command(current_member_index)

func cancel_action_select():
	if current_member_index <= 0:
		selected_actions.clear()
		state = BattleState.MAIN_COMMAND
		await battle_scene.show_main_commands()
		return

	current_member_index -= 1
	if selected_actions.size() > 0:
		selected_actions.remove_at(selected_actions.size() - 1)
	await battle_scene.focus_party_command(current_member_index)

func get_alive_party_count():
	var count = 0
	for member in party:
		if member.is_alive():
			count += 1
	return count

func get_next_alive_party_index(start_index):
	for i in range(start_index, party.size()):
		if party[i].is_alive():
			return i
	return -1

func advance_after_action_selected():
	if selected_actions.size() >= get_alive_party_count():
		state = BattleState.EXECUTE_TURN
		await execute_turn()
		return

	current_member_index = get_next_alive_party_index(current_member_index + 1)
	if current_member_index == -1:
		state = BattleState.EXECUTE_TURN
		await execute_turn()
	else:
		state = BattleState.ACTION_SELECT
		await battle_scene.focus_party_command(current_member_index)

func execute_turn():
	battle_scene.disable_all_commands()
	var turn_order = []

	for member in party:
		if member.is_alive():
			turn_order.append(member)
	for enemy in enemies:
		if enemy.is_alive():
			turn_order.append(enemy)

	turn_order.sort_custom(
		func(a, b):
			return a.speed > b.speed
	)

	for character in turn_order:
		if !character.is_alive():
			continue
		if await check_battle_end():
			return

		if party.has(character):
			var command_data = get_action_for_character(character)
			if command_data == null:
				continue
			match command_data["action"]:
				"attack":
					var target = command_data["target"]
					if target == null or !target.is_alive():
						target = get_first_alive_enemy()
					if target == null:
						return
					await battle_scene.show_message(character.char_name + " attacks!")
					var damage = target.take_damage(character.attack)
					print(target.char_name, "damage:", damage, "HP:", target.hp, "/", target.max_hp)
					await battle_scene.show_message(target.char_name + " takes " + str(damage) + " damage!")
				"defense":
					character.start_defense()
					await battle_scene.show_message(character.char_name + " defends!")
		elif enemies.has(character):
			var target = get_first_alive_party_member()
			if target == null:
				return
			await battle_scene.show_message(character.char_name + " attacks!")
			var damage = target.take_damage(character.attack)
			await battle_scene.show_message(target.char_name + " takes " + str(damage) + " damage!")

		await battle_scene.update_party_ui(party)
		await battle_scene.remove_dead_enemies()

	if await check_battle_end():
		return

	selected_actions.clear()
	current_member_index = 0
	state = BattleState.MAIN_COMMAND
	await battle_scene.show_main_commands()

func get_action_for_character(character):
	for data in selected_actions:
		if data["user"] == character:
			return data
	return null

func check_battle_end(result = null):
	var all_party_dead = true
	for member in party:
		if member.is_alive():
			all_party_dead = false

	var all_enemies_dead = true
	for enemy in enemies:
		if enemy.is_alive():
			all_enemies_dead = false

	if all_party_dead:
		state = BattleState.END
		await battle_scene.show_message("Defeated...")
		end_battle("lose")
		return true

	if all_enemies_dead:
		state = BattleState.END
		await battle_scene.show_message("Victory!")
		end_battle("win")
		return true

	return false

func get_first_alive_enemy():
	for enemy in enemies:
		if enemy.is_alive():
			return enemy
	return null

func get_first_alive_party_member():
	for member in party:
		if member.is_alive():
			return member
	return null

func end_battle(result: String):
	print(result)
	PlayerManager.can_move = true
	PlayerManager.in_battle = false
	get_viewport().gui_release_focus()
	match result:
		"win":
			PartyManager.heal_all_full()
		"lose":
			PartyManager.set_all_hp_one()
		"escape":
			PartyManager.heal_all_full()
	var open_battle_scenes = get_tree().get_nodes_in_group("battle_scenes")
	if open_battle_scenes.is_empty() and battle_scene:
		open_battle_scenes.append(battle_scene)
	for scene in open_battle_scenes:
		if scene.has_method("close_scene"):
			scene.close_scene()
		else:
			scene.queue_free()
	battle_scene = null
	battle_finished.emit(result)

func _on_battle_requested(enemy_ids) -> void:
	await start_battle(enemy_ids)

func _on_main_command_selected(action):
	match state:
		BattleState.END:
			return
		BattleState.MAIN_COMMAND:
			await handle_main_command(action)

func _on_member_action_selected(index, action):
	if state != BattleState.ACTION_SELECT:
		return
	if index != current_member_index:
		return
	match action:
		"attack":
			pending_member_index = index
			pending_action = action
			state = BattleState.TARGET_SELECT
			battle_scene.start_target_select()
		"defense":
			selected_actions.append({
				"user": party[index],
				"action": "defense"
			})
			await advance_after_action_selected()

func _on_cancel_requested():
	match state:
		BattleState.TARGET_SELECT:
			await cancel_target_select()
		BattleState.ACTION_SELECT:
			await cancel_action_select()

func cancel_target_select():
	battle_scene.stop_target_select()
	state = BattleState.ACTION_SELECT
	await battle_scene.focus_party_command(pending_member_index)

func _on_enemy_target_selected(enemy):
	if state != BattleState.TARGET_SELECT:
		return
	battle_scene.stop_target_select()
	selected_actions.append({
		"user": party[pending_member_index],
		"action": pending_action,
		"target": enemy
	})
	current_member_index = pending_member_index
	await advance_after_action_selected()
