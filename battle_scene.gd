extends Node
@onready var battle_dialog := $UI/MessageWindow/Label
@onready var main_commands := $UI/MainCommands
@onready var fight_button := $UI/MainCommands/FightButton
@onready var party_container = $UI/CommandWindow/PartyContainer
@onready var color_rect = $UI/ColorRect
var PartyStatusScene = preload(
	"res://party_status.tscn"
)
signal main_command_selected(command)
signal member_action_selected(index,action)
var messages = BattleManager.messages

func _ready() -> void:
	EventManager.battle_requested.connect(_on_battle_finished)
	print("battle scene created")
	fight_button.focus_mode = Control.FOCUS_ALL
	await get_tree().process_frame
	fight_button.grab_focus()
	
func show_message(message):
	print(message)
	battle_dialog.text = message
	await get_tree().create_timer(1.0).timeout
	
func show_main_commands():
	main_commands.visible = true
	color_rect.show()
	main_commands.show()
	await get_tree().process_frame
	fight_button.grab_focus()
func show_action_commands():
	main_commands.visible = false
	color_rect.hide()
func focus_party_command(index):
	await get_tree().process_frame
	var status=party_container.get_child(index)
	status.grab_first_button()
func update_party_ui(party):
	for child in party_container.get_children():
		child.free()

	for i in range(party.size()):
		var member = party[i]
		var status_ui = PartyStatusScene.instantiate()
		party_container.add_child(status_ui)
		status_ui.setup(member,i)
		if not status_ui.member_action_selected.is_connected(_on_member_action_selected):
			status_ui.member_action_selected.connect(_on_member_action_selected)
	await get_tree().process_frame
func update_enemy_ui(enemies):
	pass
func _on_fight_button_pressed() -> void:
	main_command_selected.emit("fight")
	print("fight")
func _on_escape_button_pressed() -> void:
	main_command_selected.emit("escape")
	queue_free()
func _on_attack_button_pressed() -> void:
	member_action_selected.emit("attack")
func _on_battle_finished() -> void:
	print("battle finished")
	queue_free()
func _on_member_action_selected(index,action):
	member_action_selected.emit(index,action)
