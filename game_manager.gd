extends Node
@export var Player: PackedScene

var next_spawn_point_name: String = ""
var next_scene_path: String = ""

func _ready() -> void:
	get_tree().connect("scene_changed",Callable(self, "_on_scene_changed"))
	
func transition_to_scene(scene_path:String,spawn_position_name:String) -> void:
	var scene_res := load(scene_path)
	get_tree().change_scene_to_packed.call_deferred(scene_res)
	
func _on_scene_changed(new_scene: Node) -> void:
	var player := new_scene.get_node_or_null("/root/Player")
	if next_spawn_point_name == "":
		return

	var spawn_point := new_scene.get_node_or_null(next_spawn_point_name)
	if spawn_point == null:
		# 名前で見つからない場合は、全 Node の中から探す
		spawn_point = new_scene.find_child(next_spawn_point_name, true)
	if spawn_point == null:
		print("SpawnPoint '%s' が見つかりません" % next_spawn_point_name)
		return

	
	PlayerManager.spawn_player(spawn_point.global_position)

	# 次回に備えてクリア
	next_spawn_point_name = ""
	next_scene_path = ""
