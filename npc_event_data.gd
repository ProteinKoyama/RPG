@tool
extends Resource
class_name NPCEventData

@export_enum("talk", "direct_talk", "battle", "cutscene", "join", "item", "learn_skill", "map", "bgm", "flag", "flag_branch", "node_animation")
var event_type := "talk":
	set(value):
		event_type = value
		notify_property_list_changed()

var dialog_id: String = ""
var direct_dialog_lines: Array[Resource] = []
var battle_enemy_ids: Array[String] = []
var battle_bgm_path: String = ""
var battle_escape_enabled := true
var battle_win_events: Array[Resource] = []
var battle_lose_events: Array[Resource] = []
var battle_escape_events: Array[Resource] = []
@export var event_key: String = ""
var member_id: String = ""
var show_join_dialog := true
var item_id: String = ""
@export var item_amount := 1
var show_item_dialog := true
var skill_member_id: String = ""
var skill_id: String = ""
var show_skill_dialog := true
var map_scene_path: String = "":
	set(value):
		map_scene_path = value
		if map_spawn_point != "" and !_get_scene_spawn_point_names(map_scene_path).has(map_spawn_point):
			map_spawn_point = ""
		notify_property_list_changed()
var map_spawn_point: String = ""
var bgm_path: String = ""
@export var flag_key: String = ""
@export var flag_value: bool = true
var branch_flag_key := ""
var branch_true_events: Array[Resource] = []
var branch_false_events: Array[Resource] = []
var target_node_path: NodePath
var animation_name := ""

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

	if event_type == "direct_talk":
		properties.append({
			"name": "direct_dialog_lines",
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_TYPE_STRING,
			"hint_string": "%d/%d:%s" % [
				TYPE_OBJECT,
				PROPERTY_HINT_RESOURCE_TYPE,
				"NPCDialogLineData"
			],
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
		properties.append({
			"name": "battle_bgm_path",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.ogg,*.mp3,*.wav",
			"usage": PROPERTY_USAGE_DEFAULT
		})
		properties.append({
			"name": "battle_escape_enabled",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT
		})
		properties.append({
			"name": "battle_win_events",
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_TYPE_STRING,
			"hint_string": "%d/%d:%s" % [
				TYPE_OBJECT,
				PROPERTY_HINT_RESOURCE_TYPE,
				"NPCEventData"
			],
			"usage": PROPERTY_USAGE_DEFAULT
		})
		properties.append({
			"name": "battle_lose_events",
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_TYPE_STRING,
			"hint_string": "%d/%d:%s" % [
				TYPE_OBJECT,
				PROPERTY_HINT_RESOURCE_TYPE,
				"NPCEventData"
			],
			"usage": PROPERTY_USAGE_DEFAULT
		})
		properties.append({
			"name": "battle_escape_events",
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_TYPE_STRING,
			"hint_string": "%d/%d:%s" % [
				TYPE_OBJECT,
				PROPERTY_HINT_RESOURCE_TYPE,
				"NPCEventData"
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
		properties.append({
			"name": "show_join_dialog",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT
		})

	if event_type == "item":
		properties.append({
			"name": "item_id",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": _get_json_key_hint("res://data/items.json"),
			"usage": PROPERTY_USAGE_DEFAULT
		})
		properties.append({
			"name": "show_item_dialog",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT
		})

	if event_type == "learn_skill":
		properties.append({
			"name": "skill_member_id",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": _get_json_key_hint("res://data/player_characters.json"),
			"usage": PROPERTY_USAGE_DEFAULT
		})
		properties.append({
			"name": "skill_id",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": _get_json_key_hint("res://data/skills.json"),
			"usage": PROPERTY_USAGE_DEFAULT
		})
		properties.append({
			"name": "show_skill_dialog",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT
		})

	if event_type == "map":
		properties.append({
			"name": "map_scene_path",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.tscn,*.scn",
			"usage": PROPERTY_USAGE_DEFAULT
		})
		properties.append({
			"name": "map_spawn_point",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": _get_scene_spawn_point_hint(map_scene_path),
			"usage": PROPERTY_USAGE_DEFAULT
		})

	if event_type == "bgm":
		properties.append({
			"name": "bgm_path",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.ogg,*.mp3,*.wav",
			"usage": PROPERTY_USAGE_DEFAULT
		})

	if event_type == "flag":
		properties.append({
			"name": "flag_key",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT
		})
		properties.append({
			"name": "flag_value",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT
		})

	if event_type == "flag_branch":
		properties.append({
			"name": "branch_flag_key",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT
		})
		properties.append({
			"name": "branch_true_events",
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_TYPE_STRING,
			"hint_string": "%d/%d:%s" % [
				TYPE_OBJECT,
				PROPERTY_HINT_RESOURCE_TYPE,
				"NPCEventData"
			],
			"usage": PROPERTY_USAGE_DEFAULT
		})
		properties.append({
			"name": "branch_false_events",
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_TYPE_STRING,
			"hint_string": "%d/%d:%s" % [
				TYPE_OBJECT,
				PROPERTY_HINT_RESOURCE_TYPE,
				"NPCEventData"
			],
			"usage": PROPERTY_USAGE_DEFAULT
		})

	if event_type == "node_animation":
		properties.append({
			"name": "target_node_path",
			"type": TYPE_NODE_PATH,
			"usage": PROPERTY_USAGE_DEFAULT
		})
		properties.append({
			"name": "animation_name",
			"type": TYPE_STRING,
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

func _get_scene_spawn_point_hint(scene_path: String) -> String:
	var names = _get_scene_spawn_point_names(scene_path)
	if names.is_empty():
		return ""
	return ",".join(names)

func _get_scene_spawn_point_names(scene_path: String) -> Array:
	if scene_path == "":
		return []
	var file = FileAccess.open(scene_path, FileAccess.READ)
	if file == null:
		return []

	var names := []
	var text = file.get_as_text()
	var marker_regex := RegEx.new()
	var marker_error = marker_regex.compile("\\[node name=\"([^\"]+)\" type=\"Marker2D\"")
	if marker_error != OK:
		return names

	for result in marker_regex.search_all(text):
		var spawn_name = result.get_string(1)
		if spawn_name != "" and !names.has(spawn_name):
			names.append(spawn_name)

	names.sort()
	return names
