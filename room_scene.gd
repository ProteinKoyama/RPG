extends Node
var game_scene1: PackedScene = preload("res://scenes/scene1.tscn")

func _ready() -> void:
	PlayerManager.spawn_player($PlayerSpawnPoint.global_position)

func _process(_delta: float) -> void:
	pass


func _on_area_2d_body_entered(_body: Node2D) -> void:
	#get_tree().change_scene_to_packed.call_deferred(game_scene1)
	GameManager.transition_to_scene("res://scenes/scene1.tscn", "FromMyRoom")
