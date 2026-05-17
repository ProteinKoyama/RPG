extends Node

var items := {}

func _ready():
	load_item_database()

func load_item_database():
	var file = FileAccess.open("res://data/items.json", FileAccess.READ)
	if file == null:
		push_error("items.json not found")
		items = {}
		return
	var text = file.get_as_text()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("items.json parse failed")
		items = {}
		return
	items = parsed

func get_item_data(item_id: String) -> Dictionary:
	if !items.has(item_id):
		return {}
	return items[item_id].duplicate(true)

func get_item_name(item_id: String) -> String:
	var item = get_item_data(item_id)
	return item.get("name", item_id)

func get_item_description(item_id: String) -> String:
	return get_item_description_from_data(get_item_data(item_id))

func get_item_description_from_data(item: Dictionary) -> String:
	var description = item.get("description", "")
	var skill_text = _get_equipment_skill_description(item)
	if skill_text == "":
		return description
	if description == "":
		return skill_text
	return description + "\n" + skill_text

func is_equipment(item_id: String) -> bool:
	return get_item_data(item_id).get("type", "") == "equipment"

func can_equip_to_slot(item_id: String, slot_id: String) -> bool:
	var item = get_item_data(item_id)
	if item.get("type", "") != "equipment":
		return false
	var item_slot = item.get("slot", "")
	if slot_id.begins_with("accessory"):
		return item_slot == "accessory"
	return item_slot == slot_id

func can_character_equip_item(item_id: String, slot_id: String, character_id: String) -> bool:
	if !can_equip_to_slot(item_id, slot_id):
		return false
	var item = get_item_data(item_id)
	var allowed_character_ids = item.get("equip_character_ids", [])
	if allowed_character_ids.is_empty():
		return true
	return allowed_character_ids.has(character_id)

func _get_equipment_skill_description(item: Dictionary) -> String:
	if item.get("type", "") != "equipment":
		return ""
	var skill_names := []
	var skill_values = item.get("skill_ids", item.get("skills", []))
	var skill_database = _get_skill_database()
	for skill_value in skill_values:
		var skill_name = ""
		if skill_database != null:
			var skill = skill_database.resolve_skill(skill_value)
			skill_name = skill.get("name", skill.get("id", ""))
		elif typeof(skill_value) == TYPE_DICTIONARY:
			skill_name = skill_value.get("name", skill_value.get("id", ""))
		else:
			skill_name = str(skill_value)
		if skill_name != "":
			skill_names.append("「%s」" % skill_name)
	if skill_names.is_empty():
		return ""
	return "使用可能：%s" % _join_strings(skill_names, "、")

func _get_skill_database():
	var tree = Engine.get_main_loop()
	if !(tree is SceneTree):
		return null
	return tree.root.get_node_or_null("SkillDatabase")

func _join_strings(values: Array, separator: String) -> String:
	var text := ""
	for i in range(values.size()):
		if i > 0:
			text += separator
		text += str(values[i])
	return text
