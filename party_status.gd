extends Control

@onready var name_label = $NameLabel
@onready var hp_text = $StatusBars/HPText
@onready var attack_button = $ActionCommands/AttackButton
var member_index:int
signal member_action_selected(index,action)
func setup(character,index):
	member_index = index
	name_label.text = character.char_name
	hp_text.text = str(character.hp)
	attack_button.focus_mode = Control.FOCUS_ALL
	print(attack_button.disabled)
func grab_first_button():
	await get_tree().process_frame
	attack_button.grab_focus()
	print(get_viewport().gui_get_focus_owner())
func _on_attack_button_pressed() -> void:
	member_action_selected.emit(member_index,"attack")

func _on_deffence_button_pressed() -> void:
	member_action_selected.emit(member_index,"deffence")
