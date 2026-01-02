extends CanvasLayer
var duration:float = 0.05
var tmp_branch = 0
@onready var name_label := $Textbox/Name
@onready var dialog_label := $Textbox/Dialog
@onready var ingame_menu := $Textbox/IngameMenu
@onready var menu_conatainer := $Textbox/VBoxContainer
var dialog = EventManager.dialog_manager_data
const tmp_dialog = [
		["name","データが入力されていません"],
		#["CallMenuCommand",["yes","no"]],
		#["BranchCommand",[["1","選択肢1が選ばれました"],["2","選択肢2が選ばれました"]]],
		["%s","会話終了"]
	]
var index := 0
func _ready():
	EventManager.dialog_manager_data = null
	if !dialog:
		dialog = tmp_dialog
	name_label.text = dialog[0][0]
	dialog_label.text = dialog[0][1]
	dialog_label.visible_ratio = 0
	ingame_menu.hide()
func _process(_delta):
	if dialog_label.visible_ratio < 1:
		dialog_label.visible_ratio += 1.0 / dialog_label.text.length() * (1.0 - duration)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_released("interact"):
		index += 1
		if index >= dialog.size() :
			EventManager.dialog_closed()
			queue_free()
			return
		if dialog[index][0] == "CallMenuCommand" or dialog[index][0] == "BranchCommand":
			if dialog[index][0] == "CallMenuCommand":
				ingame_menu.show()
				for i in len(dialog[index][1]):
					var ingame_menu_button = Button.new()
					ingame_menu_button.add_theme_font_size_override("font_size", 24)
					ingame_menu_button.text = dialog[index][1][i]
					ingame_menu_button.connect("pressed",Callable(self,"_on_ingame_menu_button_pressed").bind(i,dialog[index][1][i]))
					menu_conatainer.add_child(ingame_menu_button)
					i+=1
			if dialog[index][0] == "BranchCommand":
				name_label.text = dialog[index][1][tmp_branch][0]
				dialog_label.text = dialog[index][1][tmp_branch][1]
				if index < len(dialog) :
					index+=1
		else:
			name_label.text = dialog[index][0]
			dialog_label.text = dialog[index][1]
			if index < len(dialog) :
				pass#index+=1
			dialog_label.visible_ratio = 0

func _on_ingame_menu_button_pressed(i,item):
	tmp_branch = i
	ingame_menu.hide()
	index+=1
