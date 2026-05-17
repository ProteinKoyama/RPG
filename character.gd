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
var damage_reduction_turns := 0
var damage_reduction_rate := 1.0
var damage_reduction_just_applied := false
var attack_boost_turns := 0
var attack_boost_rate := 1.0
var attack_boost_just_applied := false
var battle_turn_count := 0
var status_effects := {}

const STATUS_MENTAL_WEAKNESS := "mental_weakness"
const STATUS_EFFECT_NAMES := {
	STATUS_MENTAL_WEAKNESS: "精神虚弱"
}

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
	skills = _resolve_skill_list(data.get("skills", []))
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
	return sp >= skill.get("sp_cost", 0) and hp >= skill.get("hp_cost", 0)
func consume_sp(amount: int):
	sp = max(0, sp - amount)
func consume_hp(amount: int):
	hp = max(0, hp - amount)
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
			var skill = _resolve_skill(learn_data.get("skill_id", learn_data.get("skill", {})))
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

func get_available_skills() -> Array:
	var available_skills = skills.duplicate(true)
	var item_database = _get_item_database()
	if item_database == null:
		return available_skills
	for item_id in equipment.values():
		if item_id == "":
			continue
		var item = item_database.get_item_data(item_id)
		var equipment_skills = _resolve_skill_list(item.get("skill_ids", item.get("skills", [])))
		for skill in equipment_skills:
			if !skill.is_empty() and !_skill_list_has_id(available_skills, skill.get("id", "")):
				available_skills.append(skill.duplicate(true))
	return available_skills

func _resolve_skill(skill_data) -> Dictionary:
	var skill_database = _get_skill_database()
	if skill_database != null:
		return skill_database.resolve_skill(skill_data)
	if typeof(skill_data) == TYPE_DICTIONARY:
		return skill_data.duplicate(true)
	return {}

func _resolve_skill_list(skill_values: Array) -> Array:
	var skill_database = _get_skill_database()
	if skill_database != null:
		return skill_database.resolve_skill_list(skill_values)
	var resolved_skills := []
	for skill_value in skill_values:
		if typeof(skill_value) == TYPE_DICTIONARY:
			resolved_skills.append(skill_value.duplicate(true))
	return resolved_skills

func _skill_list_has_id(skill_list: Array, skill_id: String) -> bool:
	if skill_id == "":
		return false
	for skill in skill_list:
		if skill.get("id", "") == skill_id:
			return true
	return false

func apply_damage_reduction(rate: float, turns: int):
	damage_reduction_rate = clampf(rate, 0.0, 1.0)
	damage_reduction_turns = max(damage_reduction_turns, turns)
	damage_reduction_just_applied = true

func apply_attack_boost(rate: float, turns: int):
	attack_boost_rate = max(rate, 1.0)
	attack_boost_turns = max(attack_boost_turns, turns)
	attack_boost_just_applied = true

func apply_status_effect(effect_id: String, turns := -1):
	if effect_id == "":
		return
	status_effects[effect_id] = {
		"turns": turns
	}

func remove_status_effect(effect_id: String):
	status_effects.erase(effect_id)

func has_status_effect(effect_id: String) -> bool:
	return status_effects.has(effect_id)

func clear_battle_effects():
	is_defending = false
	damage_reduction_turns = 0
	damage_reduction_rate = 1.0
	damage_reduction_just_applied = false
	attack_boost_turns = 0
	attack_boost_rate = 1.0
	attack_boost_just_applied = false
	status_effects.clear()
	battle_turn_count = 0

func get_active_effect_labels() -> Array:
	var labels := []
	for effect_id in status_effects.keys():
		labels.append(STATUS_EFFECT_NAMES.get(effect_id, effect_id))
	if is_defending:
		labels.append("防御")
	if damage_reduction_turns > 0:
		labels.append("軽減%dT" % damage_reduction_turns)
	if attack_boost_turns > 0:
		labels.append("攻撃UP%dT" % attack_boost_turns)
	return labels

func get_current_attack() -> int:
	if attack_boost_turns > 0:
		return max(1, int(ceil(attack * attack_boost_rate)))
	return attack

func tick_turn_effects():
	var messages := []
	if has_status_effect(STATUS_MENTAL_WEAKNESS) and is_alive():
		var damage = take_status_damage(5)
		messages.append(char_name + "は精神虚弱で" + str(damage) + "ダメージを受けた！")

	_tick_status_effect_turns()

	if damage_reduction_just_applied:
		damage_reduction_just_applied = false
	elif damage_reduction_turns > 0:
		damage_reduction_turns -= 1
		if damage_reduction_turns <= 0:
			damage_reduction_rate = 1.0
	if attack_boost_just_applied:
		attack_boost_just_applied = false
	elif attack_boost_turns > 0:
		attack_boost_turns -= 1
		if attack_boost_turns <= 0:
			attack_boost_rate = 1.0
	return messages

func _tick_status_effect_turns():
	var remove_ids := []
	for effect_id in status_effects.keys():
		var effect = status_effects[effect_id]
		var turns = int(effect.get("turns", -1))
		if turns < 0:
			continue
		turns -= 1
		if turns <= 0:
			remove_ids.append(effect_id)
		else:
			effect["turns"] = turns
			status_effects[effect_id] = effect
	for effect_id in remove_ids:
		status_effects.erase(effect_id)

func _create_equipment_slots(initial_equipment: Dictionary) -> Dictionary:
	var slots = {}
	for slot_id in EQUIPMENT_SLOTS.keys():
		slots[slot_id] = initial_equipment.get(slot_id, "")
	return slots

func equip_item(slot_id: String, item_id: String) -> String:
	if !equipment.has(slot_id):
		return ""
	var item_database = _get_item_database()
	if item_id != "" and item_database != null and !item_database.can_character_equip_item(item_id, slot_id, char_id):
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

func _get_skill_database():
	var tree = Engine.get_main_loop()
	if !(tree is SceneTree):
		return null
	return tree.root.get_node_or_null("SkillDatabase")

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
	if damage_reduction_turns > 0:
		damage = max(1, int(ceil(damage * damage_reduction_rate)))
	hp = max(0, hp - damage)
	return damage
func take_direct_damage(incoming_attack: int) -> int:
	var damage = max(1, incoming_attack)
	if is_defending:
		damage = max(1, int(ceil(damage * 0.5)))
	if damage_reduction_turns > 0:
		damage = max(1, int(ceil(damage * damage_reduction_rate)))
	hp = max(0, hp - damage)
	return damage

func take_status_damage(amount: int) -> int:
	var damage = max(0, amount)
	hp = max(0, hp - damage)
	return damage
	
func heal_full():
	hp = max_hp
	sp = 0
func set_hp_one():
	hp = 1
