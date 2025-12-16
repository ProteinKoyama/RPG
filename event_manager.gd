extends Node
signal request_show_dialog(dialog_data)
var dialog_visible := false
func show_dialog(dialog_data):
	if dialog_visible:
		return
	dialog_visible = true
	emit_signal("request_show_dialog", dialog_data)
func dialog_closed():
	dialog_visible = false
	print("closed:",dialog_visible)
