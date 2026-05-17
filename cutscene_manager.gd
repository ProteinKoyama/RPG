extends Node

signal cutscene_finished

func _ready():
	EventManager.cutscene_requested.connect(_on_cutscene_requested)
func _on_cutscene_requested(events: Array) -> void:
	await play_events(events)
	cutscene_finished.emit()
func play_events(events: Array) -> void:
	for e in events:
		match e.event_type:
			"talk":
				await EventManager.show_dialog_by_id(e.dialog_id)

			"direct_talk":
				await _show_direct_dialog(e.direct_dialog_lines)

			"battle":
				await EventManager.start_battle(
					e.battle_enemy_ids,
					e.battle_bgm_path,
					e.battle_escape_enabled
				)

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

			"map":
				await _change_map(e.map_scene_path, e.map_spawn_point)
				return

			"bgm":
				_change_bgm(e.bgm_path)

			"flag":
				_set_flag(e.flag_key, e.flag_value)

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
	match flag_key:
		"opening_done":
			EventManager.opening_done = flag_value
			print("opening_done =", flag_value)
		_:
			print("unknown flag:", flag_key, flag_value)

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
