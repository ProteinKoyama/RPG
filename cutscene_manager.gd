extends Node

signal cutscene_finished

func _ready():
	EventManager.cutscene_requested.connect(_on_cutscene_requested)
func _on_cutscene_requested(events: Array) -> void:
	await play_events(events)
	cutscene_finished.emit()
func play_events(events: Array) -> bool:
	for e in events:
		match e.event_type:
			"talk":
				await EventManager.show_dialog_by_id(e.dialog_id)

			"direct_talk":
				await _show_direct_dialog(e.direct_dialog_lines)

			"battle":
				var battle_result = await EventManager.start_battle(
					e.battle_enemy_ids,
					e.battle_bgm_path,
					e.battle_escape_enabled
				)
				if await _play_battle_result_events(battle_result, e):
					return true

			"cutscene":
				await _run_cutscene_key(e.event_key)

			"join":
				var joined = PartyManager.add_member(e.member_id)
				if e.show_join_dialog:
					var member_name = PartyManager.get_character_name(e.member_id)
					if !joined:
						await DialogManager.show_dialog_data([
							["加入", "これ以上仲間を増やせない。"]
						])
						continue
					await DialogManager.show_dialog_data([
						["加入", member_name + "が加入した！"]
					])

			"item":
				InventoryManager.add_item(e.item_id, e.item_amount)
				print("item added:", e.item_id, e.item_amount)
				if e.show_item_dialog:
					var item_name = ItemDatabase.get_item_name(e.item_id)
					await DialogManager.show_dialog_data([
						["入手", item_name + "を入手した！"]
					])

			"learn_skill":
				var learned = PartyManager.learn_member_skill(e.skill_member_id, e.skill_id)
				print("skill learned:", e.skill_member_id, e.skill_id, learned)
				if e.show_skill_dialog:
					var member_name = PartyManager.get_character_name(e.skill_member_id)
					var skill_name = SkillDatabase.get_skill_name(e.skill_id)
					if learned:
						await DialogManager.show_dialog_data([
							["習得", member_name + "は" + skill_name + "を覚えた！"]
						])
					else:
						await DialogManager.show_dialog_data([
							["習得", member_name + "は" + skill_name + "を覚えられなかった。"]
						])

			"map":
				await _change_map(e.map_scene_path, e.map_spawn_point)
				return true

			"bgm":
				_change_bgm(e.bgm_path)

			"flag":
				_set_flag(e.flag_key, e.flag_value)

			"flag_branch":
				if await _play_flag_branch_events(e):
					return true

			"node_animation":
				_play_node_animation(e.target_node_path, e.animation_name)
	return false

func _play_battle_result_events(battle_result: String, event_data) -> bool:
	var result_events := []
	match battle_result:
		"win":
			result_events = event_data.battle_win_events
		"lose":
			result_events = event_data.battle_lose_events
		"escape":
			result_events = event_data.battle_escape_events
		_:
			print("unknown battle result:", battle_result)
			return false
	if result_events.is_empty():
		return false
	return await play_events(result_events)

func _play_flag_branch_events(event_data) -> bool:
	var branch_key = event_data.branch_flag_key
	if branch_key == "":
		print("flag branch key is empty")
		return false
	var flag_value := false
	if EventManager.has_method("get_flag"):
		flag_value = EventManager.get_flag(branch_key)
	var branch_events = event_data.branch_true_events if flag_value else event_data.branch_false_events
	if branch_events.is_empty():
		return false
	return await play_events(branch_events)

func _run_cutscene_key(event_key: String) -> void:
	match event_key:
		"opening_done":
			EventManager.opening_done = true
			print("opening_done set true")

		"moeko_join":
			if PartyManager.add_member("girl"):
				print("モエ子が加入した！")

		_:
			print("unknown cutscene:", event_key)

func _set_flag(flag_key: String, flag_value: bool) -> void:
	if flag_key == "":
		print("flag key is empty")
		return
	if EventManager.has_method("set_flag"):
		EventManager.set_flag(flag_key, flag_value)
		print(flag_key, "=", flag_value)
		return
	if flag_key == "opening_done":
		EventManager.opening_done = flag_value
		print("opening_done =", flag_value)
		return
	print("unknown flag:", flag_key, flag_value)

func _play_node_animation(target_node_path: NodePath, animation_name: String) -> void:
	if target_node_path == NodePath("") or animation_name == "":
		print("node animation event is empty")
		return
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return
	var target = current_scene.get_node_or_null(target_node_path)
	if target == null:
		print("node animation target not found:", target_node_path)
		return
	if target.has_method("face_direction"):
		target.face_direction(animation_name)
		return
	if target.has_method("play_animation"):
		target.play_animation(animation_name)
		return
	if target is AnimatedSprite2D:
		target.animation = animation_name
		if target.has_method("stop"):
			target.stop()
		return
	var animated_sprite = target.get_node_or_null("AnimatedSprite2D")
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		if animated_sprite.sprite_frames.has_animation(animation_name):
			animated_sprite.animation = animation_name
			animated_sprite.stop()

func _show_direct_dialog(lines: Array) -> void:
	if lines.is_empty():
		print("direct dialog is empty")
		return

	var dialog_data := []
	for line in lines:
		if line == null:
			continue
		dialog_data.append([line.speaker_name, line.message])

	if dialog_data.is_empty():
		print("direct dialog is empty")
		return

	await DialogManager.show_dialog_data(dialog_data)

func _change_map(scene_path: String, spawn_point: String) -> void:
	if scene_path == "":
		print("map scene path is empty")
		return
	if spawn_point == "":
		print("map spawn point is empty")
		return
	await GameManager.transition_to_scene(scene_path, spawn_point)

func _change_bgm(path: String) -> void:
	if path == "":
		print("bgm path is empty")
		return
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return
	if current_scene.has_method("play_bgm_path"):
		current_scene.play_bgm_path(path)
		return
	var bgm_player = current_scene.get_node_or_null("BGMPlayer")
	if bgm_player == null:
		print("BGMPlayer not found")
		return
	var stream = load(path)
	if stream == null:
		print("bgm not found:", path)
		return
	bgm_player.stream = stream
	bgm_player.play()
