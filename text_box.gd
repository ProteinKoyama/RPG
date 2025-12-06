extends Node
var duration:float = 0.05
var tmp_branch = 0
const dialog =[
		["someone","Can you hear me?"],
		["name","HelloWorld!"],
		["%s","選択肢を表示します"],
		#["CallMenuCommand",["yes","no"]],
		#["BranchCommand",[["1","選択肢1が選ばれました"],["2","選択肢2が選ばれました"]]],
		["%s","正常に動作しています"]
	]
var index = 0
func _ready():
	index = 0
	$Name.text = ""
	$Dialog.text = ""
	$Dialog.visible_ratio = 0
	$IngameMenu.hide()
	EventManager.dialog_visible = true
func _process(_delta):
	if $Dialog.visible_ratio < 1:
		$Dialog.visible_ratio += 1.0 / $Dialog.text.length() * (1.0 - duration)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_released("interact"):
		print(index)
		if index >= len(dialog)  :
			queue_free()
			EventManager.dialog_visible = false
			return
		else:
			if dialog[index][0] == "CallMenuCommand" or dialog[index][0] == "BranchCommand":
				if dialog[index][0] == "CallMenuCommand":
					$IngameMenu.show()
					for i in len(dialog[index][1]):
						var ingame_menu_button = Button.new()
						ingame_menu_button.add_theme_font_size_override("font_size", 24)
						ingame_menu_button.text = dialog[index][1][i]
						ingame_menu_button.connect("pressed",Callable(self,"_on_ingame_menu_button_pressed").bind(i,dialog[index][1][i]))
						$IngameMenu/VBoxContainer.add_child(ingame_menu_button)
						i+=1
				if dialog[index][0] == "BranchCommand":
					$Name.text = dialog[index][1][tmp_branch][0]
					$Dialog.text = dialog[index][1][tmp_branch][1]
					if index < len(dialog) :
						index+=1
			else:
				$Name.text = dialog[index][0]
				$Dialog.text = dialog[index][1]
				if index < len(dialog) :
					index+=1
				else :pass
				$Dialog.visible_ratio = 0
		
func _on_ingame_menu_button_pressed(i,item):
	tmp_branch = i
	$IngameMenu.hide()
	index+=1
