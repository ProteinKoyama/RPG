extends RefCounted
class_name Character
var char_id: String = ""
var char_name: String
var base_max_hp: int
var max_hp: int
var hp: int
var base_max_sp: int
var max_sp: int
var sp: int
var level: int
var base_attack: int
var attack: int
var base_defense: int
var defense: int
var base_speed: int
var speed: int
var skills: Array
var learn_skills: Array
var ai_rules: Array
var equipment: Dictionary
var image_path:String
var is_defending := false
var battle_turn_count := 0

const EQUIPMENT_SLOTS := {
	"weapon": "武器",
	"body": "身体",
	"accessory1": "装飾品1",
	"accessory2": "装飾品2"
}

func _init(data: Dictionary):
	char_id = data.get("id", "")
	char_name = data.get("name", "unknown")
	base_max_hp = data.get("hp", 1)
	base_max_sp = data.get("sp", 5)
	sp = data.get("initial_sp", 0)
	level = data.get("level", 1)
	base_attack = data.get("attack", 1)
	base_defense = data.get("defense", 1)
	base_speed = data.get("speed", 1)
	skills = data.get("skills", []).duplicate(true)
	learn_skills = data.get("learn_skills", []).duplicate(true)
	ai_rules = data.get("ai_rules", []).duplicate(true)
	equipment = _create_equipment_slots(data.get("equipment", {}))
	image_path = data.get("image","")
	recalculate_stats()
	hp = max_hp
	learn_available_skills()
	
func is_alive() -> bool:
	return hp > 0

func start_defense():
	is_defending = true
func clear_defense():
	is_defending = false
func charge_sp(amount := 1):
	sp = min(max_sp, sp + amount)
func can_use_skill(skill: Dictionary) -> bool:
	return sp >= skill.get("sp_cost", 0)
func consume_sp(amount: int):
	sp = max(0, sp - amount)
func heal_hp(amount: int):
	hp = min(max_hp, hp + amount)
func heal_hp_full():
	hp = max_hp
func recover_sp(amount: int):
	sp = min(max_sp, sp + amount)
func recover_full():
	hp = max_hp
	sp = max_sp
func level_up():
	level += 1
	return learn_available_skills()
func learn_available_skills():
	var learned_skill_names = []
	for learn_data in learn_skills:
		if level >= learn_data.get("level", 1):
			var skill = learn_data.get("skill", {})
			if !skill.is_empty() and !has_skill(skill.get("id", "")):
				skills.append(skill.duplicate(true))
				learned_skill_names.append(skill.get("name", "Skill"))
	return learned_skill_names
func has_skill(skill_id: String) -> bool:
	if skill_id == "":
		return false
	for skill in skills:
		if skill.get("id", "") == skill_id:
			return true
	return false

func _create_equipment_slots(initial_equipment: Dictionary) -> Dictionary:
	var slots = {}
	for slot_id in EQUIPMENT_SLOTS.keys():
		slots[slot_id] = initial_equipment.get(slot_id, "")
	return slots

func equip_item(slot_id: String, item_id: String) -> String:
	if !equipment.has(slot_id):
		return ""
	var item_database = _get_item_database()
	if item_id != "" and item_database != null and !item_database.can_equip_to_slot(item_id, slot_id):
		return ""
	var old_item_id = equipment.get(slot_id, "")
	equipment[slot_id] = item_id
	recalculate_stats()
	return old_item_id

func unequip_item(slot_id: String) -> String:
	return equip_item(slot_id, "")

func get_equipped_item_id(slot_id: String) -> String:
	return equipment.get(slot_id, "")

func get_equipment_slot_ids() -> Array:
	return ["weapon", "body", "accessory1", "accessory2"]

func get_equipment_slot_name(slot_id: String) -> String:
	return EQUIPMENT_SLOTS.get(slot_id, slot_id)

func recalculate_stats():
	max_hp = base_max_hp
	max_sp = base_max_sp
	attack = base_attack
	defense = base_defense
	speed = base_speed

	for item_id in equipment.values():
		if item_id == "":
			continue
		var item_database = _get_item_database()
		if item_database == null:
			continue
		var item = item_database.get_item_data(item_id)
		var stats = item.get("stats", {})
		max_hp += int(stats.get("hp", 0))
		max_sp += int(stats.get("sp", 0))
		attack += int(stats.get("attack", 0))
		defense += int(stats.get("defense", 0))
		speed += int(stats.get("speed", 0))

	hp = min(hp, max_hp)
	sp = min(sp, max_sp)

func _get_item_database():
	var tree = Engine.get_main_loop()
	if !(tree is SceneTree):
		return null
	return tree.root.get_node_or_null("ItemDatabase")

func attack_target(target: Character):
	var messages = []
	messages.append(char_name + " の攻撃！")
	target.take_damage(attack)
	messages.append(target.char_name + " に " + str(attack) + " ダメージ！（残りHP: " + str(target.hp) + "）")
	return messages

func take_damage(incoming_attack: int) -> int:
	var damage = max(1, incoming_attack - defense)
	if is_defending:
		damage = max(1, int(ceil(damage * 0.5)))
	hp = max(0, hp - damage)
	return damage
func take_direct_damage(incoming_attack: int) -> int:
	var damage = max(1, incoming_attack)
	if is_defending:
		damage = max(1, int(ceil(damage * 0.5)))
	hp = max(0, hp - damage)
	return damage
	
func heal_full():
	hp = max_hp
	sp = 0
func set_hp_one():
	hp = 1
