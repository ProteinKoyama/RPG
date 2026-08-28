extends EventCommand
class_name ChangeMapEvent

@export_file("*.tscn", "*.scn") var scene_path := ""
@export var spawn_point := ""

func get_event_type() -> StringName:
	return &"map"
