extends Node

func get_text(body):
	$MessageWindow/TalkWindow/Label.text = body.text
	var message = $MessageWindow/TalkWindow/Label.text
	return message
