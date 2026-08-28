extends EventCommand
class_name GiveItemEvent

@export var item_id := ""
@export_range(1, 999, 1, "or_greater") var amount := 1
@export var show_dialog := true

func get_event_type() -> StringName:
	return &"item"
