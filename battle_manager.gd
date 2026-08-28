extends Node

signal battle_finished(battle_result)

enum BattleState {
	MAIN_COMMAND,
	ACTION_SELECT,
	SKILL_SELECT,
	ITEM_SELECT,
	PARTY_TARGET_SELECT,
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
var pending_skill = {}
var pending_item_id = ""
var escape_enabled := true
var current_turn := 1

func _ready() -> void:
	EventManager.battle_requested.connect(_on_battle_requested)

func start_battle(enemy_ids: Array, battle_bgm_path := "", can_escape := true):
	if battle_scene != null or !get_tree().get_nodes_in_group("battle_scenes").is_empty():
		print("start_battle ignored: battle scene already exists")
		return
	PlayerManager.in_battle = true
	escape_enabled = can_escape
	current_turn = 1
	var scene = preload("res://BattleScene.tscn")
	battle_scene = scene.instantiate()
	battle_scene.member_action_selected.connect(_on_member_action_selected)
	battle_scene.main_command_selected.connect(_on_main_command_selected)
	battle_scene.cancel_requested.connect(_on_cancel_requested)
	battle_scene.enemy_target_selected.connect(_on_enemy_target_selected)
	battle_scene.skill_selected.connect(_on_skill_selected)
	battle_scene.item_selected.connect(_on_item_selected)
	battle_scene.party_target_selected.connect(_on_party_target_selected)
	get_tree().current_scene.add_child(battle_scene)
	battle_scene.set_escape_enabled(escape_enabled)
	battle_scene.play_battle_bgm(battle_bgm_path)

	party = PartyManager.get_party()
	var starting_aura_skill_id = PartyManager.get_active_party_aura_skill_id_for_battle()
	apply_party_battle_aura(starting_aura_skill_id)
	await battle_scene.update_party_ui(party)

	enemies.clear()
	for enemy_id in enemy_ids:
		var enemy_data = EnemyDatabase.get_enemy_data(enemy_id)
		var enemy = Character.new(enemy_data)
		enemies.append(enemy)

	await battle_scene.update_enemy_ui(enemies)
	if starting_aura_skill_id != "":
		var starting_aura = SkillDatabase.get_skill_data(starting_aura_skill_id)
		if starting_aura.get("aura_id", starting_aura.get("id", "")) != "":
			await battle_scene.show_message(starting_aura.get("name", "特技") + "が発動した！")
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
			if !escape_enabled:
				await battle_scene.show_message("逃げられない！")
				await battle_scene.show_main_commands()
				return
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
	reset_turn_limited_effects()
	var turn_order = []

	for member in party:
		if member.is_alive():
			var command_data = get_action_for_character(member)
			if command_data != null:
				turn_order.append({
					"character": member,
					"command": command_data,
					"priority_group": get_action_priority_group(command_data),
					"priority": get_action_priority(command_data)
				})
	for enemy in enemies:
		if enemy.is_alive():
			enemy.battle_turn_count += 1
			var enemy_action = choose_enemy_action(enemy)
			turn_order.append({
				"character": enemy,
				"command": enemy_action,
				"priority_group": get_action_priority_group(enemy_action),
				"priority": get_action_priority(enemy_action)
			})

	turn_order.sort_custom(
		func(a, b):
			var group_a = int(a.get("priority_group", 0))
			var group_b = int(b.get("priority_group", 0))
			if group_a != group_b:
				return group_a > group_b
			var priority_a = int(a.get("priority", 0))
			var priority_b = int(b.get("priority", 0))
			if priority_a != priority_b:
				return priority_a > priority_b
			return a.get("character").get_current_speed() > b.get("character").get_current_speed()
	)

	for turn_data in turn_order:
		var character = turn_data.get("character")
		var command_data = turn_data.get("command", {})
		if !character.is_alive():
			continue
		if await check_battle_end():
			return

		if party.has(character):
			await execute_character_action(character, command_data, get_first_alive_enemy())
		elif enemies.has(character):
			await execute_character_action(character, command_data, get_first_alive_party_member())

		await battle_scene.update_party_ui(party)
		battle_scene.refresh_enemy_status_ui()
		await battle_scene.remove_dead_enemies()

	if await check_battle_end():
		return

	await tick_turn_effects()
	await battle_scene.update_party_ui(party)
	battle_scene.refresh_enemy_status_ui()
	await battle_scene.remove_dead_enemies()
	if await check_battle_end():
		return
	selected_actions.clear()
	current_member_index = 0
	state = BattleState.MAIN_COMMAND
	current_turn += 1
	await battle_scene.show_message("%dターン目" % current_turn)
	await battle_scene.show_main_commands()

func get_action_priority_group(command_data: Dictionary) -> int:
	if command_data.get("action", "") != "skill":
		return 0
	var skill = command_data.get("skill", {})
	if skill.get("effect_type", "") == "party_aura":
		return 1
	return 0

func get_action_priority(command_data: Dictionary) -> int:
	if command_data.get("action", "") != "skill":
		return 0
	var skill = command_data.get("skill", {})
	return int(skill.get("priority", 0))

func execute_character_action(character, command_data: Dictionary, fallback_target):
	match command_data.get("action", "attack"):
		"attack":
			var target = command_data.get("target", fallback_target)
			if target == null or !target.is_alive():
				target = fallback_target
			if target == null:
				return
			await execute_attack_action(character, target)
		"skill":
			var skill = command_data.get("skill", {})
			var target = command_data.get("target", fallback_target)
			var skill_target = skill.get("target", "enemy")
			if skill_target == "self":
				target = character
			elif skill_target == "all_enemies":
				target = get_opposing_group(character)
			elif skill_target == "enemy" and (target == null or !target.is_alive()):
				target = fallback_target
			if skill.is_empty() or target == null:
				return
			await execute_skill_action(character, skill, target)
		"defense":
			character.start_defense()
			await battle_scene.show_message(character.char_name + "は防御している！")
		"charge":
			var before_sp = character.sp
			character.charge_sp()
			await battle_scene.show_message(character.char_name + " チャージ" + str(before_sp) + "→" + str(character.sp))
		"item":
			var item_id = command_data.get("item_id", "")
			var target = command_data.get("target", character)
			await execute_item_action(character, item_id, target)

func execute_attack_action(character, target):
	await battle_scene.show_message(character.char_name + "の攻撃！")
	var damage = target.take_damage(character.get_current_attack() + character.get_damage_bonus())
	print(target.char_name, "damage:", damage, "HP:", target.hp, "/", target.max_hp)
	await battle_scene.show_message(target.char_name + "に" + str(damage) + "ダメージ！")
	await execute_howling_follow_up(character, target, damage)
	await execute_counter_if_needed(target, character)

func execute_skill_action(character, skill: Dictionary, target):
	if !character.can_use_skill(skill):
		await battle_scene.show_message(character.char_name + "はコストが足りない！")
		return

	character.consume_sp(skill.get("sp_cost", 0))
	character.consume_hp(skill.get("hp_cost", 0))
	if skill.get("effect_type", "") == "party_aura":
		var aura_id = skill.get("aura_id", skill.get("id", ""))
		PartyManager.set_active_party_aura_skill_id(skill.get("id", aura_id))
		apply_party_battle_aura(aura_id)
		await battle_scene.show_message(character.char_name + "は" + skill.get("name", "特技") + "を使った！")
		await battle_scene.show_message("パーティの状態が" + skill.get("name", "特技") + "に切り替わった！")
		await battle_scene.update_party_ui(party)
		return

	if skill.get("effect_type", "") == "damage_reduction":
		var rate = float(skill.get("reduction_rate", 1.0))
		var turns = int(skill.get("turns", 1))
		target.apply_damage_reduction(rate, turns)
		if skill.has("attack_rate"):
			target.apply_attack_boost(float(skill.get("attack_rate", 1.0)), turns)
		await battle_scene.show_message(character.char_name + "は" + skill.get("name", "特技") + "を使った！")
		await battle_scene.show_message(target.char_name + "は力を固めた！")
		return

	if skill.get("effect_type", "") == "counter":
		var turns = int(skill.get("turns", 1))
		character.start_counter(turns)
		await battle_scene.show_message(character.char_name + "は" + skill.get("name", "特技") + "を使った！")
		await battle_scene.show_message(character.char_name + "は反撃の構えを取った！")
		return

	if skill.get("effect_type", "") == "howling":
		character.start_howling()
		await battle_scene.show_message(character.char_name + "は" + skill.get("name", "特技") + "を使った！")
		await battle_scene.show_message(character.char_name + "はハウリング状態になった！")
		await battle_scene.update_party_ui(party)
		return

	if skill.get("effect_type", "") == "inspect":
		await battle_scene.show_message(character.char_name + "は" + skill.get("name", "特技") + "を使った！")
		await show_inspect_message(target)
		return

	if skill.get("effect_type", "") == "fixed_damage":
		var fixed_damage = int(skill.get("fixed_damage", 0)) + character.get_damage_bonus()
		var fixed_element = skill.get("element", "")
		if typeof(target) == TYPE_ARRAY:
			await battle_scene.show_message(character.char_name + "は" + skill.get("name", "特技") + "を使った！")
			for target_member in target:
				if target_member == null or !target_member.is_alive():
					continue
				var area_damage = target_member.take_direct_damage(fixed_damage, fixed_element)
				await battle_scene.show_message(target_member.char_name + "に" + str(area_damage) + "ダメージ！")
				await execute_howling_follow_up(character, target_member, area_damage)
				await execute_counter_if_needed(target_member, character)
			return
		var damage = target.take_direct_damage(fixed_damage, fixed_element)
		await battle_scene.show_message(character.char_name + "は" + skill.get("name", "特技") + "を使った！")
		await battle_scene.show_message(target.char_name + "に" + str(damage) + "ダメージ！")
		await execute_howling_follow_up(character, target, damage)
		await execute_counter_if_needed(target, character)
		return

	if skill.get("effect_type", "") == "heal_hp":
		var heal_amount = int(skill.get("heal_amount", 0))
		var before_hp = target.hp
		target.heal_hp(heal_amount)
		var recovered = target.hp - before_hp
		await battle_scene.show_message(character.char_name + "は" + skill.get("name", "特技") + "を使った！")
		await battle_scene.show_message(target.char_name + "のHPが" + str(recovered) + "回復した！")
		return

	if skill.get("effect_type", "") == "status":
		var status_id = skill.get("status_id", "")
		var turns = int(skill.get("turns", -1))
		await battle_scene.show_message(character.char_name + "は" + skill.get("name", "特技") + "を使った！")
		if typeof(target) == TYPE_ARRAY:
			for target_member in target:
				if target_member == null or !target_member.is_alive():
					continue
				if target_member.has_method("apply_status_effect"):
					target_member.apply_status_effect(status_id, turns)
				await battle_scene.show_message(target_member.char_name + "は" + _get_status_effect_name(status_id) + "になった！")
			return
		if target.has_method("apply_status_effect"):
			target.apply_status_effect(status_id, turns)
		await battle_scene.show_message(target.char_name + "は" + _get_status_effect_name(status_id) + "になった！")
		return

	var power = skill.get("power", 1.0)
	var skill_attack = int(character.get_current_attack() * power) + character.get_damage_bonus()
	var element = skill.get("element", "")
	var damage = 0
	if skill.get("ignore_defense", false):
		damage = target.take_direct_damage(skill_attack, element)
	else:
		damage = target.take_damage(skill_attack, element)

	await battle_scene.show_message(character.char_name + "は" + skill.get("name", "特技") + "を使った！")
	await battle_scene.show_message(target.char_name + "に" + str(damage) + "ダメージ！")
	await execute_howling_follow_up(character, target, damage)
	await execute_counter_if_needed(target, character)

func reset_turn_limited_effects():
	for member in party:
		if member != null and member.has_method("reset_turn_limited_effects"):
			member.reset_turn_limited_effects()
	for enemy in enemies:
		if enemy != null and enemy.has_method("reset_turn_limited_effects"):
			enemy.reset_turn_limited_effects()

func execute_howling_follow_up(attacker, target, original_damage: int):
	if attacker == null or target == null:
		return
	if original_damage <= 0 or !target.is_alive():
		return
	var allies = get_allies_for_character(attacker)
	if allies.is_empty():
		return
	for ally in allies:
		if ally == null or ally == attacker:
			continue
		if !ally.is_alive():
			continue
		if !ally.has_method("can_trigger_howling") or !ally.can_trigger_howling():
			continue
		ally.mark_howling_triggered()
		await battle_scene.show_message(ally.char_name + "のハウリング！")
		var damage = target.take_direct_damage(original_damage)
		await battle_scene.show_message(target.char_name + "に" + str(damage) + "ダメージ！")
		await execute_counter_if_needed(target, ally)

func get_allies_for_character(character) -> Array:
	if party.has(character):
		return party
	if enemies.has(character):
		return enemies
	return []

func execute_counter_if_needed(defender, attacker):
	if defender == null or attacker == null:
		return
	if !defender.is_alive() or !attacker.is_alive():
		return
	if !defender.has_method("can_counter") or !defender.can_counter():
		return
	defender.consume_counter()
	await battle_scene.show_message(defender.char_name + "のカウンター！")
	var counter_damage = attacker.take_damage(defender.get_current_defense() + defender.get_damage_bonus())
	await battle_scene.show_message(attacker.char_name + "に" + str(counter_damage) + "ダメージ！")

func execute_item_action(character, item_id: String, target):
	if item_id == "":
		return
	var item = ItemDatabase.get_item_data(item_id)
	if item.is_empty():
		return
	var item_name = item.get("name", item_id)
	if InventoryManager.use_item(item_id, target, true):
		await battle_scene.show_message(character.char_name + "は" + item_name + "を使った！")
	else:
		await battle_scene.show_message(item_name + "は使えない！")

func show_inspect_message(target):
	if target == null:
		return
	await battle_scene.show_message(
		"%s HP %d/%d SP %d/%d" % [
			target.char_name,
			target.hp,
			target.max_hp,
			target.sp,
			target.max_sp
		]
	)
	await battle_scene.show_message(
		"攻撃 %d 防御 %d 素早さ %d" % [
			target.attack,
			target.defense,
			target.speed
		]
	)
	var weakness_text = _get_element_weakness_text(target)
	if weakness_text != "":
		await battle_scene.show_message("弱点: " + weakness_text)
	else:
		await battle_scene.show_message("弱点: なし")

func _get_element_weakness_text(target) -> String:
	if target == null or !("element_weaknesses" in target):
		return ""
	var names := []
	for element in target.element_weaknesses.keys():
		var rate = float(target.element_weaknesses[element])
		if rate > 1.0:
			names.append(_get_element_name(element) + " x" + str(rate))
	return _join_strings(names, " / ")

func _get_element_name(element: String) -> String:
	match element:
		"electric":
			return "電気"
	return element

func _join_strings(values: Array, separator: String) -> String:
	var text := ""
	for i in range(values.size()):
		if i > 0:
			text += separator
		text += str(values[i])
	return text

func choose_enemy_action(enemy):
	var rules = enemy.ai_rules.duplicate()
	rules.sort_custom(
		func(a, b):
			return int(a.get("priority", 0)) > int(b.get("priority", 0))
	)

	for rule in rules:
		if !enemy_ai_rule_matches(enemy, rule):
			continue
		var action_data = build_enemy_action(enemy, rule)
		if !action_data.is_empty():
			return action_data

	return {
		"action": "attack",
		"target": get_first_alive_party_member()
	}

func enemy_ai_rule_matches(enemy, rule: Dictionary) -> bool:
	match rule.get("condition", "always"):
		"always":
			return true
		"turn_interval":
			var interval = max(1, int(rule.get("interval", 1)))
			return enemy.battle_turn_count % interval == 0
		"turn":
			return enemy.battle_turn_count == int(rule.get("turn", 1))
		"hp_below":
			var hp_rate = float(rule.get("hp_rate", 0.5))
			return float(enemy.hp) / float(enemy.max_hp) <= hp_rate
		"sp_below":
			return enemy.sp < int(rule.get("sp", 1))
		"sp_below_skill":
			var skill = get_skill_by_id(enemy, rule.get("skill_id", ""))
			if skill.is_empty():
				return false
			return enemy.sp < skill.get("sp_cost", 0)
	return false

func build_enemy_action(enemy, rule: Dictionary) -> Dictionary:
	var action = rule.get("action", "attack")
	match action:
		"skill":
			var skill = get_skill_by_id(enemy, rule.get("skill_id", ""))
			if skill.is_empty() or !enemy.can_use_skill(skill):
				return {}
			return {
				"action": "skill",
				"skill": skill,
				"target": get_first_alive_party_member()
			}
		"charge":
			return {
				"action": "charge"
			}
		"defense":
			return {
				"action": "defense"
			}
		"attack":
			return {
				"action": "attack",
				"target": get_first_alive_party_member()
			}
	return {}

func get_skill_by_id(character, skill_id: String) -> Dictionary:
	for skill in character.skills:
		if skill.get("id", "") == skill_id:
			return skill
	return {}

func get_action_for_character(character):
	for data in selected_actions:
		if data["user"] == character:
			return data
	return null

func tick_turn_effects():
	for member in party:
		for message in member.tick_turn_effects():
			await battle_scene.show_message(message)
	for enemy in enemies:
		for message in enemy.tick_turn_effects():
			await battle_scene.show_message(message)

func _get_status_effect_name(status_id: String) -> String:
	match status_id:
		"mental_weakness":
			return "精神虚弱"
	return status_id

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
		await battle_scene.show_message("全滅した...")
		end_battle("lose")
		return true

	if all_enemies_dead:
		state = BattleState.END
		await battle_scene.show_message("勝利！")
		await apply_victory_rewards()
		end_battle("win")
		return true

	return false

func apply_victory_rewards():
	for member in party:
		if !member.is_alive():
			continue
		var learned_skill_names = member.level_up()
		await battle_scene.show_message(member.char_name + "はレベル" + str(member.level) + "になった！")
		for skill_name in learned_skill_names:
			await battle_scene.show_message(member.char_name + "は" + skill_name + "を覚えた！")

func get_first_alive_enemy():
	for enemy in enemies:
		if enemy.is_alive():
			return enemy
	return null

func get_opposing_group(character) -> Array:
	if party.has(character):
		return enemies
	if enemies.has(character):
		return party
	return []

func get_first_alive_party_member():
	for member in party:
		if member.is_alive():
			return member
	return null

func apply_party_battle_aura(aura_id: String):
	for member in party:
		if member != null and member.has_method("set_party_aura"):
			member.set_party_aura(aura_id)

func end_battle(result: String):
	print(result)
	clear_battle_effects()
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

func clear_battle_effects():
	for member in party:
		if member != null and member.has_method("clear_battle_effects"):
			member.clear_battle_effects()
	for enemy in enemies:
		if enemy != null and enemy.has_method("clear_battle_effects"):
			enemy.clear_battle_effects()

func _on_battle_requested(enemy_ids, battle_bgm_path := "", can_escape := true) -> void:
	await start_battle(enemy_ids, battle_bgm_path, can_escape)

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
			pending_skill = {}
			state = BattleState.TARGET_SELECT
			battle_scene.start_target_select()
		"skill":
			state = BattleState.SKILL_SELECT
			pending_member_index = index
			pending_action = "skill"
			pending_item_id = ""
			await battle_scene.show_skill_select(party[index].get_available_skills(), party[index].sp, party[index].hp)
		"item":
			state = BattleState.ITEM_SELECT
			pending_member_index = index
			pending_action = "item"
			pending_skill = {}
			var usable_items = InventoryManager.get_usable_items(true)
			if usable_items.is_empty():
				await battle_scene.show_message("使えるアイテムがない！")
				state = BattleState.ACTION_SELECT
				await battle_scene.focus_party_command(index)
				return
			await battle_scene.show_item_select(usable_items)
		"defense":
			selected_actions.append({
				"user": party[index],
				"action": "defense"
			})
			await advance_after_action_selected()
		"charge":
			selected_actions.append({
				"user": party[index],
				"action": "charge"
			})
			await advance_after_action_selected()

func _on_cancel_requested():
	match state:
		BattleState.TARGET_SELECT:
			await cancel_target_select()
		BattleState.SKILL_SELECT:
			await cancel_skill_select()
		BattleState.ITEM_SELECT:
			await cancel_item_select()
		BattleState.PARTY_TARGET_SELECT:
			await cancel_party_target_select()
		BattleState.ACTION_SELECT:
			await cancel_action_select()

func cancel_skill_select():
	battle_scene.hide_skill_select()
	state = BattleState.ACTION_SELECT
	await battle_scene.focus_party_command(pending_member_index)

func cancel_item_select():
	battle_scene.hide_skill_select()
	state = BattleState.ACTION_SELECT
	await battle_scene.focus_party_command(pending_member_index)

func cancel_party_target_select():
	battle_scene.stop_party_target_select()
	if pending_action == "skill":
		state = BattleState.SKILL_SELECT
		await battle_scene.show_skill_select(
			party[pending_member_index].get_available_skills(),
			party[pending_member_index].sp,
			party[pending_member_index].hp
		)
		return
	state = BattleState.ITEM_SELECT
	var usable_items = InventoryManager.get_usable_items(true)
	await battle_scene.show_item_select(usable_items)

func cancel_target_select():
	battle_scene.stop_target_select()
	state = BattleState.ACTION_SELECT
	await battle_scene.focus_party_command(pending_member_index)

func _on_skill_selected(skill):
	if state != BattleState.SKILL_SELECT:
		return
	pending_skill = skill
	if skill.get("target", "enemy") == "all_enemies":
		selected_actions.append({
			"user": party[pending_member_index],
			"action": "skill",
			"skill": pending_skill,
			"target": enemies
		})
		current_member_index = pending_member_index
		await advance_after_action_selected()
		return
	if skill.get("target", "enemy") == "self":
		selected_actions.append({
			"user": party[pending_member_index],
			"action": "skill",
			"skill": pending_skill,
			"target": party[pending_member_index]
		})
		current_member_index = pending_member_index
		await advance_after_action_selected()
		return
	if skill.get("target", "enemy") == "party":
		selected_actions.append({
			"user": party[pending_member_index],
			"action": "skill",
			"skill": pending_skill,
			"target": party
		})
		current_member_index = pending_member_index
		await advance_after_action_selected()
		return
	if skill.get("target", "enemy") == "ally":
		state = BattleState.PARTY_TARGET_SELECT
		await battle_scene.start_party_target_select(pending_member_index)
		return
	state = BattleState.TARGET_SELECT
	battle_scene.start_target_select()

func _on_item_selected(item_id):
	if state != BattleState.ITEM_SELECT:
		return
	pending_item_id = item_id
	state = BattleState.PARTY_TARGET_SELECT
	await battle_scene.start_party_target_select(pending_member_index)

func _on_party_target_selected(index):
	if state != BattleState.PARTY_TARGET_SELECT:
		return
	battle_scene.stop_party_target_select()
	if pending_action == "skill":
		selected_actions.append({
			"user": party[pending_member_index],
			"action": "skill",
			"skill": pending_skill,
			"target": party[index]
		})
	else:
		selected_actions.append({
			"user": party[pending_member_index],
			"action": "item",
			"item_id": pending_item_id,
			"target": party[index]
		})
	current_member_index = pending_member_index
	await advance_after_action_selected()

func _on_enemy_target_selected(enemy):
	if state != BattleState.TARGET_SELECT:
		return
	battle_scene.stop_target_select()
	selected_actions.append({
		"user": party[pending_member_index],
		"action": pending_action,
		"skill": pending_skill,
		"target": enemy
	})
	current_member_index = pending_member_index
	await advance_after_action_selected()
