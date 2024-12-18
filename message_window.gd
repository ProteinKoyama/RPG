extends CanvasLayer

var char_name
var full_text = ""
var visible_text = ""
var current_index = 0
var page_length = 100
var window_open_flag = false

func _ready() -> void:
	self.hide()
	visible_text = ""
	current_index = 0
	page_length = 100
	full_text = $TalkWindow/Label.text

func _process(delta: float) -> void:
	if $TalkWindow/Label.text != "" and Input.is_action_just_pressed("interact"):
		if !window_open_flag:
			full_text = $TalkWindow/Label.text
			window_open_flag = true
		self.show()
	$TalkWindow/Label.text = full_text.substr(current_index,page_length)
	if Input.is_action_just_pressed("talk"):
		print($TalkWindow/Label.text,"process")
		self.show()
		show_page()
	else:
		$TalkWindow/HBoxContainer/TextureRect.texture = null
		$TalkWindow/HBoxContainer/VBoxContainer/Label.text = ""
		$TalkWindow/Label.text = full_text
func show_page():
	visible_text = full_text.substr(current_index,page_length)
	$TalkWindow/Label.text = visible_text
	current_index += page_length
	if current_index >= full_text.length():
		current_index = full_text.length()
	if $TalkWindow/Label.text == "":
		self.hide
	print($TalkWindow/Label.text)
func _on_button_pressed() -> void:
	show_page()
	
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
