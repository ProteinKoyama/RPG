extends EventCommand
class_name CutsceneEvent

@export var event_key := ""

func get_event_type() -> StringName:
	return &"cutscene"
