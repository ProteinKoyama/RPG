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
func _on_battle_finished(result):
	PlayerManager.can_move = true
	
func start_cutscene(event_keys) -> void:
	PlayerManager.can_move = false
	cutscene_requested.emit(event_keys)
	print("cutscene requested")
