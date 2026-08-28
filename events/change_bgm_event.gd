extends EventCommand
class_name ChangeBgmEvent

@export_file("*.ogg", "*.mp3", "*.wav") var bgm_path := ""

func get_event_type() -> StringName:
	return &"bgm"
