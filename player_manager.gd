extends Node

var player_scene := preload("res://player.tscn")
var player_instance: Node2D
var player = null
var can_move = true
var in_battle = false
func spawn_player(pos: Vector2):
	if player_instance == null:
		player_instance = player_scene.instantiate()
		get_tree().get_root().add_child.call_deferred(player_instance)

	player_instance.global_position = pos

func stop_player_animation():
	if player_instance != null and player_instance.has_method("stop_movement_animation"):
		player_instance.stop_movement_animation()
