extends Node

var items := {}

func _ready():
	load_initial_inventory()

func load_initial_inventory():
	var file = FileAccess.open("res://data/initial_inventory.json", FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	items.clear()
	for item_id in parsed.keys():
		add_item(item_id, int(parsed[item_id]))

func add_item(item_id: String, amount := 1):
	if item_id == "" or amount <= 0:
		return
	items[item_id] = get_item_count(item_id) + amount

func remove_item(item_id: String, amount := 1) -> bool:
	if get_item_count(item_id) < amount:
		return false
	items[item_id] -= amount
	if items[item_id] <= 0:
		items.erase(item_id)
	return true

func get_item_count(item_id: String) -> int:
	return int(items.get(item_id, 0))

func get_all_items() -> Dictionary:
	return items.duplicate()

func get_usable_items(in_battle := false) -> Dictionary:
	var result := {}
	for item_id in items.keys():
		if can_use_item(item_id, in_battle):
			result[item_id] = items[item_id]
	return result

func can_use_item(item_id: String, in_battle := false) -> bool:
	var item_database = _get_item_database()
	if item_database == null:
		return false
	var item = item_database.get_item_data(item_id)
	if get_item_count(item_id) <= 0 or !item.get("usable", false):
		return false
	if in_battle and !item.get("usable_in_battle", true):
		return false
	return true

func use_item(item_id: String, target, in_battle := false) -> bool:
	if !can_use_item(item_id, in_battle):
		return false
	var item_database = _get_item_database()
	var item = item_database.get_item_data(item_id)
	if !_apply_item_effects(item, target):
		return false
	if !item.get("consume_on_use", true):
		return true
	return remove_item(item_id, 1)

func get_equipment_for_slot(slot_id: String) -> Array:
	var result := []
	var item_database = _get_item_database()
	if item_database == null:
		return result
	for item_id in items.keys():
		if get_item_count(item_id) > 0 and item_database.can_equip_to_slot(item_id, slot_id):
			result.append(item_id)
	return result

func take_equipped_item(item_id: String):
	if item_id != "":
		add_item(item_id, 1)

func give_item_to_equipment(item_id: String) -> bool:
	if item_id == "":
		return true
	return remove_item(item_id, 1)

func _apply_item_effects(item: Dictionary, target) -> bool:
	if target == null:
		return false
	var effects = item.get("effects", {})
	var applied := false
	if effects.get("hp_full", false):
		if typeof(target) == TYPE_ARRAY:
			for member in target:
				if member != null and member.has_method("heal_hp_full"):
					member.heal_hp_full()
					applied = true
		elif target.has_method("heal_hp_full"):
			target.heal_hp_full()
			applied = true
	if effects.get("full_recover", false):
		if typeof(target) == TYPE_ARRAY:
			for member in target:
				if member != null and member.has_method("recover_full"):
					member.recover_full()
					applied = true
		elif target.has_method("recover_full"):
			target.recover_full()
			applied = true
	if int(effects.get("hp", 0)) != 0 and target.has_method("heal_hp"):
		target.heal_hp(int(effects.get("hp", 0)))
		applied = true
	if int(effects.get("sp", 0)) != 0 and target.has_method("recover_sp"):
		target.recover_sp(int(effects.get("sp", 0)))
		applied = true
	return applied

func _get_item_database():
	var tree = Engine.get_main_loop()
	if !(tree is SceneTree):
		return null
	return tree.root.get_node_or_null("ItemDatabase")
