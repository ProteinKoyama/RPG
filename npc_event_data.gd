@tool
extends Resource
class_name NPCEventData

@export_enum("talk", "battle", "cutscene", "join", "flag")
var event_type := "talk":
	set(value):
		event_type = value
		notify_property_list_changed()

var dialog_id: String = ""
var battle_enemy_ids: Array[String] = []
@export var event_key: String = ""
var member_id: String = ""
@export var flag_key: String = ""
@export var flag_value: bool = true

func _get_property_list() -> Array:
	var properties := []

	if event_type == "talk":
		properties.append({
			"name": "dialog_id",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": _get_json_key_hint("res://data/dialogs.json"),
			"usage": PROPERTY_USAGE_DEFAULT
		})

	if event_type == "battle":
		properties.append({
			"name": "battle_enemy_ids",
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_TYPE_STRING,
			"hint_string": "%d/%d:%s" % [
				TYPE_STRING,
				PROPERTY_HINT_ENUM,
				_get_json_key_hint("res://data/enemies.json")
			],
			"usage": PROPERTY_USAGE_DEFAULT
		})

	if event_type == "join":
		properties.append({
			"name": "member_id",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": _get_json_key_hint("res://data/player_characters.json"),
			"usage": PROPERTY_USAGE_DEFAULT
		})

	return properties

func _get_json_key_hint(path: String) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return ""

	var keys = parsed.keys()
	keys.sort()
	return ",".join(keys)
