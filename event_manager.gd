extends Node
signal request_show_dialog(dialog_data)
signal battle_requested(enemy_data)
var dialog_visible := false
var dialog_manager_data
var opening_done := false
func show_dialog(dialog_data,is_battle=null):
	PlayerManager.can_move = false
	if dialog_visible:
		return
	dialog_visible = true
	emit_signal("request_show_dialog", dialog_data)
	return is_battle
func dialog_closed():
	PlayerManager.can_move = true
	dialog_visible = false
func start_battle(enemy_ids):
	PlayerManager.can_move = false
	emit_signal("battle_requested", enemy_ids)
