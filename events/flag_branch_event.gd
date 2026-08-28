extends EventCommand
class_name FlagBranchEvent

@export var flag_key := ""
@export_group("Branches")
@export var when_true: EventSequence
@export var when_false: EventSequence

func get_event_type() -> StringName:
	return &"flag_branch"
