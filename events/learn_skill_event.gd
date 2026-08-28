extends EventCommand
class_name LearnSkillEvent

@export var member_id := ""
@export var skill_id := ""
@export var show_dialog := true

func get_event_type() -> StringName:
	return &"learn_skill"
