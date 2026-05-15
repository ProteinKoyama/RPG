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
