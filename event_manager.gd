extends Node

const EVENT_DATABASE_PATH := "res://data/events.json"

signal request_show_dialog(dialog_id)
signal battle_requested(enemy_ids, battle_bgm_path, escape_enabled)
signal cutscene_requested(event_source)
var opening_done := false
var dialog_visible := false
var flags := {}
var npc_event_active := false
var npc_interaction_count := 0
var json_events: Dictionary = {}

func _ready():
	load_json_event_database()
	BattleManager.battle_finished.connect(_on_battle_finished)

func load_json_event_database() -> void:
	json_events.clear()
	var file := FileAccess.open(EVENT_DATABASE_PATH, FileAccess.READ)
	if file == null:
		push_error("events.json open failed: " + EVENT_DATABASE_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if !(parsed is Dictionary):
		push_error("events.json root must be an object")
		return
	json_events = parsed

func get_json_event_sequence(event_id: String) -> Array:
	if event_id == "":
		return []
	if !json_events.has(event_id):
		push_error("JSON event not found: " + event_id)
		return []
	var entry = json_events[event_id]
	if entry is Array:
		return entry.duplicate(true)
	if entry is Dictionary and entry.get("events", null) is Array:
		return entry["events"].duplicate(true)
	push_error("JSON event must contain an events array: " + event_id)
	return []

func has_json_event(event_id: String) -> bool:
	return json_events.has(event_id)

func show_dialog_by_id(dialog_id):
	if dialog_visible:
		return
	request_show_dialog.emit(dialog_id)
	PlayerManager.can_move = false
func dialog_closed():
	PlayerManager.can_move = true
	dialog_visible = false

func start_battle(enemy_ids, battle_bgm_path := "", escape_enabled := true):
	if PlayerManager.in_battle:
		print("battle request ignored: already in battle")
		return
	print("battle requested")
	PlayerManager.can_move = false
	PlayerManager.in_battle = true
	PlayerManager.stop_player_animation()
	emit_signal("battle_requested", enemy_ids, battle_bgm_path, escape_enabled)
	var result = await BattleManager.battle_finished
	return result
func _on_battle_finished(result):
	PlayerManager.can_move = true
	
func start_cutscene(event_source) -> void:
	# 会話・NPC移動・画面遷移などを含む演出全体で、ゲーム操作を共通して無効化する。
	# 会話UIが一時的に can_move を戻しても、このロックが演出終了まで優先される。
	PlayerManager.acquire_input_lock()
	var cutscene_manager = _get_cutscene_manager()
	cutscene_requested.emit(event_source)
	print("cutscene requested")
	if cutscene_manager != null:
		await cutscene_manager.cutscene_finished
	PlayerManager.release_input_lock()
	if !PlayerManager.in_battle and !PlayerManager.is_input_locked():
		PlayerManager.can_move = true

func _get_cutscene_manager():
	var tree = Engine.get_main_loop()
	if !(tree is SceneTree):
		return null
	return tree.root.get_node_or_null("CutsceneManager")

func set_flag(flag_key: String, flag_value: bool) -> void:
	if flag_key == "":
		return
	flags[flag_key] = flag_value
	if flag_key == "opening_done":
		opening_done = flag_value

func get_flag(flag_key: String) -> bool:
	if flag_key == "":
		return false
	if flag_key == "opening_done":
		return opening_done
	return bool(flags.get(flag_key, false))

func register_npc_interaction() -> void:
	npc_interaction_count += 1

func unregister_npc_interaction() -> void:
	npc_interaction_count = max(npc_interaction_count - 1, 0)

func begin_npc_event() -> void:
	npc_event_active = true

func end_npc_event() -> void:
	npc_event_active = false

func is_npc_event_blocking() -> bool:
	return npc_event_active or npc_interaction_count > 0
