extends CanvasLayer

var char_name
var full_text = ""
var visible_text = ""
var dialog_index = 0
var page_length = 100
var window_open_flag = false

var dialog = ["文章1","文章２文章２文章２文章２文章２","文章\n3"]

func _ready() -> void:
	self.hide()
	#visible_text = ""
	#dialog_index = 0
	#page_length = 100
	#full_text = $TalkWindow/Label.text
	$TalkWindow/Label.text = dialog[dialog_index]
	if Input.is_action_just_pressed("talk"):
		if dialog_index < dialog.size() - 1:
			dialog_index += 1
			update_dialog()
		else:
			pass
func update_dialog():
	$TalkWindow/Label.text = full_text.substr(dialog_index,page_length)
func _process(delta: float) -> void:
	$TalkWindow/Label.text = full_text.substr(dialog_index,page_length)
	if Input.is_action_just_pressed("talk"):
		if $TalkWindow/Label.text == "":
			self.hide()
		#show_page()
	if Input.is_action_just_pressed("talk"):
		if self.visible:
			self.hide()
	else:
		$TalkWindow/HBoxContainer/TextureRect.texture = null
		$TalkWindow/HBoxContainer/VBoxContainer/Label.text = ""
#func show_page():
	#visible_text = full_text.substr(dialog_index,page_length)
	#$TalkWindow/Label.text = visible_text
	#dialog_index += page_length
	#if dialog_index >= full_text.length():
		#dialog_index = full_text.length()
	#if $TalkWindow/Label.text == "":
		#self.hide
	#print($TalkWindow/Label.text)
	
func _on_myself_character_interacted_signal(body) -> void:
	self.show()
	char_name = body.name
	if body.name:
		$TalkWindow/HBoxContainer/TextureRect.texture = load("res://assets/"+body.name+"_icon.png")
	if body:
		$TalkWindow/HBoxContainer/VBoxContainer/Label.text = char_name
	for child in body.get_children():
		if child.name == "Label":
			$TalkWindow/Label.text = child.text
