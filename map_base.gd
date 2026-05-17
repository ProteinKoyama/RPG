extends Node2D
class_name MapBase

@export var default_spawn_point_name := "PlayerSpawnPoint"
@export var bgm: AudioStream
@export var auto_play_bgm := true

@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

func _ready() -> void:
	_play_bgm()
	call_deferred("_spawn_player_at_default_if_needed")

func _play_bgm() -> void:
	if !auto_play_bgm:
		return
	if bgm == null:
		return
	play_bgm_stream(bgm)

func play_bgm_stream(stream: AudioStream) -> void:
	if stream == null:
		return
	bgm_player.stream = stream
	bgm_player.play()

func play_bgm_path(path: String) -> void:
	if path == "":
		return
	var stream = load(path)
	if stream == null:
		print("map bgm not found:", path)
		return
	play_bgm_stream(stream)

func stop_bgm() -> void:
	bgm_player.stop()

func _spawn_player_at_default_if_needed() -> void:
	var game_manager = _get_autoload("GameManager")
	if game_manager != null and game_manager.next_spawn_point_name != "":
		return

	var spawn_point = find_child(default_spawn_point_name, true)
	if spawn_point == null:
		print("Default spawn point '%s' not found" % default_spawn_point_name)
		return

	var player_manager = _get_autoload("PlayerManager")
	if player_manager != null:
		player_manager.spawn_player(spawn_point.global_position)

func _get_autoload(node_name: String):
	var tree = Engine.get_main_loop()
	if !(tree is SceneTree):
		return null
	return tree.root.get_node_or_null(node_name)
