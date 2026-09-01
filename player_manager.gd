extends Node

var player_scene := preload("res://player.tscn")
var player_instance: Node2D
var player = null
var _movement_requested := true
var _input_lock_count := 0
var can_move: bool:
	get:
		return _movement_requested and _input_lock_count == 0
	set(value):
		_movement_requested = value
var in_battle = false

func acquire_input_lock() -> void:
	_input_lock_count += 1
	stop_player_animation()

func release_input_lock() -> void:
	_input_lock_count = maxi(_input_lock_count - 1, 0)

func is_input_locked() -> bool:
	return _input_lock_count > 0

func spawn_player(pos: Vector2):
	if player_instance == null:
		player_instance = player_scene.instantiate()
		get_tree().get_root().add_child.call_deferred(player_instance)

	player_instance.global_position = pos

func stop_player_animation():
	if player_instance != null and player_instance.has_method("stop_movement_animation"):
		player_instance.stop_movement_animation()
