extends EventCommand
class_name DirectTalkEvent

@export var lines: Array[NPCDialogLineData] = []

func get_event_type() -> StringName:
	return &"direct_talk"
