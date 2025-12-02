extends Node
@export var Player: PackedScene

var next_spawn_point_name: String = ""
var next_scene_path: String = ""

func _ready() -> void:
	get_tree().connect("scene_changed", Callable(self, "_on_scene_changed"))

func transition_to_scene(scene_path:String, spawn_position_name:String) -> void:
	await TransitionManager.fade_out(0.2)
	next_scene_path = scene_path
	next_spawn_point_name = spawn_position_name

	var scene_res := load(scene_path)
	get_tree().change_scene_to_packed.call_deferred(scene_res)


func _on_scene_changed() -> void:
	if next_spawn_point_name == "":
		return

	# スポーンポイント検索（再帰）
	var spawn_point = get_tree().current_scene.get_node_or_null(next_spawn_point_name)
	if spawn_point == null:
		spawn_point = get_tree().current_scene.find_child(next_spawn_point_name, true)
	if spawn_point == null:
		print("SpawnPoint '%s' が見つかりません" % next_spawn_point_name)
		return
	# プレイヤーを移動
	PlayerManager.spawn_player(spawn_point.global_position)
	await TransitionManager.fade_in()
	next_spawn_point_name = ""
	next_scene_path = ""
