extends Node

signal cutscene_finished

func _ready():
	EventManager.cutscene_requested.connect(_on_cutscene_requested)
func _on_cutscene_requested(event_source) -> void:
	await play_event_source(event_source)
	cutscene_finished.emit()

func play_event_source(event_source) -> bool:
	if event_source is String or event_source is StringName:
		var json_events := EventManager.get_json_event_sequence(String(event_source))
		if json_events.is_empty():
			return false
		return await play_events(json_events)
	if event_source is Dictionary:
		var dictionary_events = event_source.get("events", [])
		if dictionary_events is Array:
			return await play_events(dictionary_events)
	if event_source is EventSequence:
		return await play_events(event_source.events)
	if event_source is Array:
		return await play_events(event_source)
	print("invalid event source:", event_source)
	return false

func play_events(events: Array) -> bool:
	for e in events:
		if e == null:
			continue
		match _get_event_type(e):
			"talk":
				var dialog_id = e.get("dialog_id", "") if e is Dictionary else e.dialog_id
				var variables = e.get("variables", {}) if e is Dictionary else {}
				await DialogManager.show_dialog_by_id(dialog_id, variables)

			"direct_talk":
				var lines
				if e is Dictionary:
					lines = e.get("lines", [])
				else:
					lines = e.lines if e is DirectTalkEvent else e.direct_dialog_lines
				await _show_direct_dialog(lines)

			"choice":
				if !(e is Dictionary):
					push_error("choice event must be defined in JSON")
					continue
				var options = e.get("options", [])
				if !(options is Array) or options.is_empty():
					push_error("choice event options are empty")
					continue
				var selected_index := await DialogManager.show_choice(
					e.get("prompt_dialog_id", ""),
					options
				)
				if selected_index < 0 or selected_index >= options.size():
					continue
				var selected_option = options[selected_index]
				if !(selected_option is Dictionary):
					continue
				var selected_event_id := str(selected_option.get("event_id", ""))
				if selected_event_id != "":
					if await play_event_source(selected_event_id):
						return true

			"battle":
				var enemy_ids
				var bgm_path
				var escape_enabled
				if e is Dictionary:
					enemy_ids = e.get("enemy_ids", [])
					bgm_path = e.get("bgm_path", "")
					escape_enabled = bool(e.get("escape_enabled", true))
				else:
					enemy_ids = e.enemy_ids if e is BattleEvent else e.battle_enemy_ids
					bgm_path = e.bgm_path if e is BattleEvent else e.battle_bgm_path
					escape_enabled = e.escape_enabled if e is BattleEvent else e.battle_escape_enabled
				var battle_result = await EventManager.start_battle(
					enemy_ids,
					bgm_path,
					escape_enabled
				)
				if await _play_battle_result_events(battle_result, e):
					return true

			"cutscene":
				var event_key = e.get("event_key", "") if e is Dictionary else e.event_key
				await _run_cutscene_key(event_key)

			"join":
				var member_id = e.get("member_id", "") if e is Dictionary else e.member_id
				var joined = PartyManager.add_member(member_id)
				var show_dialog
				if e is Dictionary:
					show_dialog = bool(e.get("show_dialog", true))
				else:
					show_dialog = e.show_dialog if e is JoinMemberEvent else e.show_join_dialog
				if show_dialog:
					var member_name = PartyManager.get_character_name(member_id)
					if !joined:
						await DialogManager.show_dialog_by_id("system_party_full")
						continue
					await DialogManager.show_dialog_by_id("system_member_joined", {
						"member_name": member_name
					})

			"item":
				var item_id = e.get("item_id", "") if e is Dictionary else e.item_id
				var amount
				var show_dialog
				if e is Dictionary:
					amount = int(e.get("amount", 1))
					show_dialog = bool(e.get("show_dialog", true))
				else:
					amount = e.amount if e is GiveItemEvent else e.item_amount
					show_dialog = e.show_dialog if e is GiveItemEvent else e.show_item_dialog
				InventoryManager.add_item(item_id, amount)
				print("item added:", item_id, amount)
				if show_dialog:
					var item_name = ItemDatabase.get_item_name(item_id)
					await DialogManager.show_dialog_by_id("system_item_received", {
						"item_name": item_name
					})

			"learn_skill":
				var member_id
				var skill_id
				var show_dialog
				if e is Dictionary:
					member_id = e.get("member_id", "")
					skill_id = e.get("skill_id", "")
					show_dialog = bool(e.get("show_dialog", true))
				else:
					member_id = e.member_id if e is LearnSkillEvent else e.skill_member_id
					skill_id = e.skill_id
					show_dialog = e.show_dialog if e is LearnSkillEvent else e.show_skill_dialog
				var learned = PartyManager.learn_member_skill(member_id, skill_id)
				print("skill learned:", member_id, skill_id, learned)
				if show_dialog:
					var member_name = PartyManager.get_character_name(member_id)
					var skill_name = SkillDatabase.get_skill_name(skill_id)
					if learned:
						await DialogManager.show_dialog_by_id("system_skill_learned", {
							"member_name": member_name,
							"skill_name": skill_name
						})
					else:
						await DialogManager.show_dialog_by_id("system_skill_learn_failed", {
							"member_name": member_name,
							"skill_name": skill_name
						})

			"map":
				var scene_path
				var spawn_point
				if e is Dictionary:
					scene_path = e.get("scene_path", "")
					spawn_point = e.get("spawn_point", "")
				else:
					scene_path = e.scene_path if e is ChangeMapEvent else e.map_scene_path
					spawn_point = e.spawn_point if e is ChangeMapEvent else e.map_spawn_point
				await _change_map(scene_path, spawn_point)
				return true

			"bgm":
				var path = e.get("bgm_path", "") if e is Dictionary else e.bgm_path
				_change_bgm(path)

			"flag":
				var flag_key = e.get("flag_key", "") if e is Dictionary else e.flag_key
				var flag_value
				if e is Dictionary:
					flag_value = bool(e.get("value", true))
				else:
					flag_value = e.value if e is SetFlagEvent else e.flag_value
				_set_flag(flag_key, flag_value)

			"flag_branch":
				if await _play_flag_branch_events(e):
					return true

			"node_animation":
				var target_path = NodePath(e.get("target_node_path", "")) if e is Dictionary else e.target_node_path
				var animation_name = e.get("animation_name", "") if e is Dictionary else e.animation_name
				_play_node_animation(target_path, animation_name)

			"move_node":
				if !(e is Dictionary):
					push_error("move_node event must be defined in JSON")
					continue
				await _move_node(
					NodePath(e.get("target_node_path", "")),
					NodePath(e.get("destination_node_path", "")),
					float(e.get("speed", 120.0)),
					str(e.get("axis", "both"))
				)

			"remove_node":
				var remove_target_path = NodePath(e.get("target_node_path", "")) if e is Dictionary else NodePath("")
				_remove_node(remove_target_path)
	return false

func _get_event_type(event_data) -> StringName:
	if event_data is Dictionary:
		var json_type := StringName(event_data.get("type", ""))
		match json_type:
			&"dialog":
				return &"talk" if event_data.has("dialog_id") else &"direct_talk"
			&"set_flag":
				return &"flag"
			&"give_item":
				return &"item"
			&"change_map":
				return &"map"
		return json_type
	if event_data is EventCommand:
		return event_data.get_event_type()
	return StringName(event_data.event_type)

func _play_battle_result_events(battle_result: String, event_data) -> bool:
	var result_source = null
	match battle_result:
		"win":
			if event_data is Dictionary:
				result_source = event_data.get("on_win", "")
			else:
				result_source = event_data.on_win if event_data is BattleEvent else event_data.battle_win_events
		"lose":
			if event_data is Dictionary:
				result_source = event_data.get("on_lose", "")
			else:
				result_source = event_data.on_lose if event_data is BattleEvent else event_data.battle_lose_events
		"escape":
			if event_data is Dictionary:
				result_source = event_data.get("on_escape", "")
			else:
				result_source = event_data.on_escape if event_data is BattleEvent else event_data.battle_escape_events
		_:
			print("unknown battle result:", battle_result)
			return false
	if _is_event_source_empty(result_source):
		return false
	return await play_event_source(result_source)

func _play_flag_branch_events(event_data) -> bool:
	var branch_key
	if event_data is Dictionary:
		branch_key = event_data.get("flag_key", "")
	else:
		branch_key = event_data.flag_key if event_data is FlagBranchEvent else event_data.branch_flag_key
	if branch_key == "":
		print("flag branch key is empty")
		return false
	var flag_value := false
	if EventManager.has_method("get_flag"):
		flag_value = EventManager.get_flag(branch_key)
	var branch_source
	if event_data is Dictionary:
		branch_source = event_data.get("when_true", "") if flag_value else event_data.get("when_false", "")
	elif event_data is FlagBranchEvent:
		branch_source = event_data.when_true if flag_value else event_data.when_false
	else:
		branch_source = event_data.branch_true_events if flag_value else event_data.branch_false_events
	if _is_event_source_empty(branch_source):
		return false
	return await play_event_source(branch_source)

func _is_event_source_empty(event_source) -> bool:
	if event_source == null:
		return true
	if event_source is String or event_source is StringName:
		return String(event_source).is_empty()
	if event_source is Dictionary:
		return event_source.is_empty() or event_source.get("events", []).is_empty()
	if event_source is EventSequence:
		return event_source.is_empty()
	return event_source.is_empty()

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

func _move_node(
	target_node_path: NodePath,
	destination_node_path: NodePath,
	speed: float,
	axis := "both"
) -> void:
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return
	var target = current_scene.get_node_or_null(target_node_path)
	var destination = current_scene.get_node_or_null(destination_node_path)
	if target == null:
		push_error("move_node target not found: " + str(target_node_path))
		return
	if destination == null:
		push_error("move_node destination not found: " + str(destination_node_path))
		return
	var destination_position: Vector2 = destination.global_position
	match axis:
		"horizontal":
			destination_position.y = target.global_position.y
		"vertical":
			destination_position.x = target.global_position.x
	if target.has_method("move_to_position"):
		await target.move_to_position(destination_position, speed)
		return
	var duration: float = target.global_position.distance_to(destination_position) / maxf(speed, 1.0)
	var tween := create_tween()
	tween.tween_property(target, "global_position", destination_position, duration)
	await tween.finished

func _remove_node(target_node_path: NodePath) -> void:
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return
	var target = current_scene.get_node_or_null(target_node_path)
	if target == null:
		push_error("remove_node target not found: " + str(target_node_path))
		return
	target.queue_free()

func _show_direct_dialog(lines: Array) -> void:
	if lines.is_empty():
		print("direct dialog is empty")
		return

	var dialog_data := []
	for line in lines:
		if line == null:
			continue
		if line is Dictionary:
			dialog_data.append([line.get("speaker", ""), line.get("message", "")])
		elif line is Array and line.size() >= 2:
			dialog_data.append([line[0], line[1]])
		else:
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
