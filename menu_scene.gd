extends Control

@onready var party_list = $PanelContainer/HBoxContainer/PartyList
@onready var detail_panel = $PanelContainer/HBoxContainer/DetailPanel

var current_party : Array = []

func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func open_menu():
	current_party = PartyManager.get_party()
	visible = true
	_update_party_list()
	_update_detail_panel()

func close_menu():
	visible = false

func _input(event):
	if event.is_action_pressed("menu"):
		MenuManager.close_menu()
		get_viewport().set_input_as_handled()

func _update_party_list():
	for child in party_list.get_children():
		child.queue_free()

	for i in range(current_party.size()):
		var member = current_party[i]
		var button = Button.new()
		button.text = member.char_name
		button.focus_mode = Control.FOCUS_ALL
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_member_pressed.bind(i))
		party_list.add_child(button)

	await get_tree().process_frame
	if party_list.get_child_count() > 0:
		party_list.get_child(0).grab_focus()

func _update_detail_panel():
	for child in detail_panel.get_children():
		child.queue_free()

	for member in current_party:
		var row = VBoxContainer.new()

		var name = Label.new()
		name.text = "名前: " + member.char_name

		var hp = Label.new()
		hp.text = "HP: %d / %d" % [member.hp, member.max_hp]

		var atk = Label.new()
		atk.text = "攻撃: %d" % member.attack

		var def = Label.new()
		def.text = "防御: %d" % member.defense

		var spd = Label.new()
		spd.text = "素早さ: %d" % member.speed

		row.add_child(name)
		row.add_child(hp)
		row.add_child(atk)
		row.add_child(def)
		row.add_child(spd)

		var frame = PanelContainer.new()
		frame.add_child(row)
		detail_panel.add_child(frame)

func _on_member_pressed(index):
	pass
