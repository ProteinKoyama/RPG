extends Control

@onready var name_label = $NameLabel
@onready var hp_text = $StatusBars/HPText
@onready var attack_button = $ActionCommands/AttackButton
@onready var skill_button = $ActionCommands/SkillButton
@onready var defense_button = $ActionCommands/DefenseButton
@onready var item_button = $ActionCommands/ItemButton
var member_index:int
signal member_action_selected(index,action)
func _ready() -> void:
	attack_button.focus_neighbor_left = NodePath("")
	attack_button.focus_neighbor_right = NodePath("")
	attack_button.focus_next = NodePath("")
	attack_button.focus_previous = NodePath("")
	
func setup(character,index):
	member_index = index
	name_label.text = character.char_name
	hp_text.text = str(character.hp)
	attack_button.focus_mode = Control.FOCUS_ALL

func grab_first_button():
	await get_tree().process_frame
	attack_button.grab_focus()
func set_command_enabled(enabled):
	attack_button.disabled = not enabled
	skill_button.disabled = not enabled
	defense_button.disabled = not enabled
	item_button.disabled = not enabled
	if enabled:
		attack_button.focus_mode = Control.FOCUS_ALL
	else:
		attack_button.focus_mode = Control.FOCUS_NONE
	skill_button.disabled = not enabled
	if enabled:
		skill_button.focus_mode = Control.FOCUS_ALL
	else:
		skill_button.focus_mode = Control.FOCUS_NONE
	if enabled:
		defense_button.focus_mode = Control.FOCUS_ALL
	else:
		defense_button.focus_mode = Control.FOCUS_NONE
	if enabled:
		item_button.focus_mode = Control.FOCUS_ALL
	else:
		item_button.focus_mode = Control.FOCUS_NONE
func _on_attack_button_pressed() -> void:
	member_action_selected.emit(member_index,"attack")

func _on_defense_button_pressed() -> void:
	member_action_selected.emit(member_index,"defense")
