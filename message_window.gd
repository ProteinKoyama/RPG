extends CanvasLayer

var char_name

func _ready() -> void:
	self.hide()

func _process(delta: float) -> void:
	if self.visible:
		if Input.is_action_pressed("talk"):
			self.hide()
	else:
		$TalkWindow/HBoxContainer/TextureRect.texture = null
		$TalkWindow/HBoxContainer/VBoxContainer/Label.text = ""

func _on_button_pressed() -> void:
	self.hide()
	
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
