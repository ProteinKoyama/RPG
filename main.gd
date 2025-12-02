extends Node
var game_scene: PackedScene = preload("res://scenes/room_scene.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("_change_scene")
func _change_scene() -> void:
	get_tree().change_scene_to_packed(game_scene)
	load_map(game_scene)
func load_map(map_scene: PackedScene):
	var map = map_scene.instantiate()
	add_child(map)
