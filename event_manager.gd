extends Node
signal request_show_dialog(dialog_data)
var dialog_visible:bool
func message() -> void:
	pass

func show_dialog(dialog_data):
	emit_signal("request_show_dialog", dialog_data)
