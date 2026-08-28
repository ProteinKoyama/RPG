extends EventCommand
class_name TalkEvent

@export var dialog_id := ""

func get_event_type() -> StringName:
	return &"talk"
