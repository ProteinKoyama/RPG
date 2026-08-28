extends EventCommand
class_name BattleEvent

@export var enemy_ids: Array[String] = []
@export_file("*.ogg", "*.mp3", "*.wav") var bgm_path := ""
@export var escape_enabled := true
@export_group("Result Sequences")
@export var on_win: EventSequence
@export var on_lose: EventSequence
@export var on_escape: EventSequence

func get_event_type() -> StringName:
	return &"battle"
