extends EventCommand
class_name NodeAnimationEvent

@export var target_node_path: NodePath
@export var animation_name := ""

func get_event_type() -> StringName:
	return &"node_animation"
