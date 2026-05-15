extends Control

@onready var name_label = $NameLabel
@onready var hp_text = $StatusBars/HPText
@onready var attack_button = $ActionCommands/AttackButton
@onready var sp_text = $StatusBars/SPText
@onready var skill_button = $ActionCommands/SkillButton
@onready var charge_button = $ActionCommands/ChargeButton
@onready var defense_button = $ActionCommands/DefenseButton
@onready var item_button = $ActionCommands/ItemButton
var member_index:int
var member_ref
var target_select_enabled := false
signal member_action_selected(index,action)
func _ready() -> void:
	attack_button.focus_neighbor_left = NodePath("")
	attack_button.focus_neighbor_right = NodePath("")
	attack_button.focus_next = NodePath("")
	attack_button.focus_previous = NodePath("")
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	
func setup(character,index):
	member_ref = character
	member_index = index
	name_label.text = character.char_name + " Lv." + str(character.level)
	hp_text.text = "HP " + str(character.hp) + "/" + str(character.max_hp)
	sp_text.text = "SP " + str(character.sp) + "/" + str(character.max_sp)
	attack_button.focus_mode = Control.FOCUS_ALL

func grab_first_button():
	await get_tree().process_frame
	attack_button.grab_focus()
func set_command_enabled(enabled):
	attack_button.disabled = not enabled
	skill_button.disabled = not enabled
	charge_button.disabled = not enabled
	defense_button.disabled = not enabled
	item_button.disabled = not enabled
	if enabled:
		attack_button.focus_mode = Control.FOCUS_ALL
	else:
		attack_button.focus_mode = Control.FOCUS_NONE
	if enabled:
		skill_button.focus_mode = Control.FOCUS_ALL
	else:
		skill_button.focus_mode = Control.FOCUS_NONE
	if enabled:
		charge_button.focus_mode = Control.FOCUS_ALL
	else:
		charge_button.focus_mode = Control.FOCUS_NONE
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

func _on_skill_button_pressed() -> void:
	member_action_selected.emit(member_index,"skill")

func _on_defense_button_pressed() -> void:
	member_action_selected.emit(member_index,"defense")

func _on_charge_button_pressed() -> void:
	member_action_selected.emit(member_index,"charge")

func _on_item_button_pressed() -> void:
	member_action_selected.emit(member_index,"item")

func enable_target_select():
	target_select_enabled = true
	focus_mode = Control.FOCUS_ALL
	set_command_enabled(false)

func disable_target_select():
	target_select_enabled = false
	focus_mode = Control.FOCUS_NONE
	modulate = Color.WHITE
	scale = Vector2.ONE

func _on_focus_entered():
	if target_select_enabled:
		modulate = Color(1.0, 1.0, 0.55)
		scale = Vector2(1.05, 1.05)

func _on_focus_exited():
	if target_select_enabled:
		modulate = Color.WHITE
		scale = Vector2.ONE
