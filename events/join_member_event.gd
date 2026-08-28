extends EventCommand
class_name JoinMemberEvent

@export var member_id := ""
@export var show_dialog := true

func get_event_type() -> StringName:
	return &"join"
