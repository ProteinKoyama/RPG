extends Node
var DialogScene := preload("res://DialogRoot.tscn")
var BattleScene := preload("res://BattleScene.tscn")
var is_battle
func _ready() -> void:
	if !EventManager.opening_done:
		PartyManager.add_member("girl")
		EventManager.opening_done = true
	else: pass
	_spawn_player_for_direct_scene_start()
	EventManager.connect("request_show_dialog", Callable(self, "_on_request_show_dialog"))

func _spawn_player_for_direct_scene_start() -> void:
	# シーン遷移中はGameManagerが指定されたマーカーへ配置する。
	if GameManager.next_spawn_point_name != "":
		return
	var spawn_point := get_node_or_null("PlayerSpawnPoint") as Marker2D
	if spawn_point == null:
		spawn_point = get_node_or_null("FromScene1") as Marker2D
	if spawn_point == null:
		push_error("Player spawn point not found in " + scene_file_path)
		return
	PlayerManager.spawn_player(spawn_point.global_position)
func _process(_delta: float) -> void:
	pass

func _on_area_2d_body_entered(_body: Node2D) -> void:
	GameManager.transition_to_scene("res://scenes/scene1.tscn", "FromMyRoom")
	EventManager.request_show_dialog.connect(_on_request_show_dialog)
var interacting:= false

func _on_roma_character_interacted_signal(_body) -> void:
	if interacting and !EventManager.dialog_visible:
		interacting = false
		return
	if interacting:
		return
	interacting = true
	if !EventManager.dialog_visible:
		is_battle = EventManager.show_dialog([["roma","test"]],"battle")
		
func _on_request_show_dialog(dialog_data):
	var dialog = DialogScene.instantiate()
	dialog.dialog_finished.connect(_on_dialog_finished)
	
func _on_dialog_finished():
	if is_battle == "battle":
		EventManager.start_battle(["slime","slime"])
	else:
		pass
