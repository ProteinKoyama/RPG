extends Resource
class_name NPCEventData

@export_enum("talk", "battle", "cutscene", "join", "flag")
var event_type := "talk"

@export var dialog_id: String = ""
@export var battle_enemy_ids: Array[String] = []
@export var event_key: String = ""
@export var member_id: String = ""
@export var flag_key: String = ""
@export var flag_value: bool = true
