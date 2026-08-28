extends EventCommand
class_name SetFlagEvent

@export var flag_key := ""
@export var value := true

func get_event_type() -> StringName:
	return &"flag"
