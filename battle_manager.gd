extends Node
var party = []
var enemies = []
var battle_scene = null
var messages = []
var battle_result:String
signal battle_finished(battle_result)
enum BattleState {
	MAIN_COMMAND,
	ACTION_SELECT,
	EXECUTE_TURN,
	END
}
var state = BattleState.MAIN_COMMAND
var selected_main_command = ""
var current_member_index = 0
var selected_actions = []
func _ready() -> void:
	EventManager.battle_requested.connect(_on_battle_requested)
	
func start_battle(enemy_ids:Array):
	var scene = preload("res://BattleScene.tscn")
	battle_scene = scene.instantiate()
	battle_scene.member_action_selected.connect(_on_member_action_selected)
	battle_scene.main_command_selected.connect(_on_main_command_selected)
	get_tree().current_scene.add_child(battle_scene)
	party = PartyManager.get_party()
	battle_scene.update_party_ui(party)
	enemies.clear()
	for enemy_id in enemy_ids:
		var enemy_data = EnemyDatabase.get_enemy_data(
			enemy_id
		)
		var enemy = Character.new(enemy_data)
		enemies.append(enemy)
	print("battle scene created")
	await battle_scene.ready
	battle_scene.update_enemy_ui(enemies)
	# Signal接続
	battle_scene.action_selected.connect(_on_main_command_selected)
	# UI初期化
	state = BattleState.MAIN_COMMAND
	battle_scene.show_main_commands()
	begin_command_select()
func handle_main_command(action):
	match action:
		"fight":
			state = BattleState.ACTION_SELECT
			battle_scene.show_action_commands()
		"escape":
			end_battle("escape")
func begin_command_select():
	selected_actions.clear()
	current_member_index=0
	battle_scene.focus_party_command(
		current_member_index
	)
func handle_action_select(index,action):
	selected_actions.append({
		"user":party[index],
		"action":action
	})
	current_member_index+=1
	if current_member_index>=party.size():
		state=BattleState.EXECUTE_TURN
		await execute_turn()
	else:
		battle_scene.focus_party_command(
			current_member_index
		)
func execute_turn():
	var turn_order = []
	# 生存中の味方追加
	for member in party:
		if member.is_alive():
			turn_order.append(member)

	# 生存中の敵追加
	for enemy in enemies:
		if enemy.is_alive():
			turn_order.append(enemy)

	# 素早さ順
	turn_order.sort_custom(
		func(a,b):
			return a.speed > b.speed
	)

	# 行動開始
	for character in turn_order:
		# 戦闘終了チェック
		if await check_battle_end():
			return
		# 味方ターン
		if party.has(character):
			var command_data=get_action_for_character(character)
			if command_data==null:
				continue
			match command_data["action"]:
				"attack":
					var target=get_first_alive_enemy()
					if target==null:
						return
					await battle_scene.show_message(character.char_name+" の攻撃！")
					target.take_damage(character.attack)
					await battle_scene.show_message(target.char_name+" に "+str(character.attack)+" ダメージ！")
				"deffence":
					pass
# 敵ターン
		elif enemies.has(character):
			var target=get_first_alive_party_member()
			if target==null:
				return
			await battle_scene.show_message(character.char_name+" の攻撃！")
			target.take_damage(character.attack)
			await battle_scene.show_message(target.char_name+" は "+str(character.attack)+" ダメージ受けた！")
		# UI更新
		battle_scene.update_party_ui(party)
		battle_scene.update_enemy_ui(enemies)
	if battle_scene:
		selected_actions.clear()
		current_member_index=0
		state=BattleState.MAIN_COMMAND
		battle_scene.focus_party_command(0)
	state = BattleState.MAIN_COMMAND
	battle_scene.show_main_commands()
	
func get_action_for_character(character):
	for data in selected_actions:
		if data["user"]==character:
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
	# 敗北
	if all_party_dead:
		state = BattleState.END
		await battle_scene.show_message(
			"全滅した…"
		)
		end_battle("lose")
		return true
	# 勝利
	if all_enemies_dead:
		state = BattleState.END
		await battle_scene.show_message(
			"勝利！"
		)
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

func end_battle(result : String):
	print(result)
	PlayerManager.can_move = true
	get_viewport().gui_release_focus()
	if battle_scene:
		battle_scene.queue_free()
		battle_scene = null
	battle_finished.emit(result)
func _on_battle_requested(enemy_ids) -> void:
	start_battle(enemy_ids)
func _on_main_command_selected(action):
	match state:
		BattleState.END:
			return
		BattleState.MAIN_COMMAND:
			handle_main_command(action)
func _on_member_action_selected(index,action):
	selected_actions.append({
		"user":party[index],
		"action":action
	})
	current_member_index+=1
	if current_member_index>=party.size():
		await execute_turn()
	else:
		battle_scene.focus_party_command(
			current_member_index
		)
