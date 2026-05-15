extends Node

signal request_show_dialog(dialog_id)
signal battle_requested(enemy_ids)
signal cutscene_requested(event_keys)
var opening_done := false
var dialog_visible := false

func _ready():
	BattleManager.battle_finished.connect(_on_battle_finished)

func show_dialog_by_id(dialog_id):
	if dialog_visible:
		return
	request_show_dialog.emit(dialog_id)
	PlayerManager.can_move = false
func dialog_closed():
	PlayerManager.can_move = true
	dialog_visible = false

func start_battle(enemy_ids):
	if PlayerManager.in_battle:
		print("battle request ignored: already in battle")
		return
	print("battle requested")
	PlayerManager.can_move = false
	PlayerManager.in_battle = true
	PlayerManager.stop_player_animation()
	emit_signal("battle_requested", enemy_ids)
	var result = await BattleManager.battle_finished
	return result
func _on_battle_finished(result):
	PlayerManager.can_move = true
	
func start_cutscene(event_keys) -> void:
	PlayerManager.can_move = false
	var cutscene_manager = _get_cutscene_manager()
	cutscene_requested.emit(event_keys)
	print("cutscene requested")
	if cutscene_manager != null:
		await cutscene_manager.cutscene_finished

func _get_cutscene_manager():
	var tree = Engine.get_main_loop()
	if !(tree is SceneTree):
		return null
	return tree.root.get_node_or_null("CutsceneManager")
