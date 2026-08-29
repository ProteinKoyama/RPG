extends Node

var skills := {}

func _ready():
	load_skill_database()

func load_skill_database():
	var file = FileAccess.open("res://data/skills.json", FileAccess.READ)
	if file == null:
		push_error("skills.json not found")
		skills = {}
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("skills.json parse failed")
		skills = {}
		return
	skills = parsed

func get_skill_data(skill_id: String) -> Dictionary:
	if !skills.has(skill_id):
		return {}
	return skills[skill_id].duplicate(true)

func get_skill_name(skill_id: String) -> String:
	var skill = get_skill_data(skill_id)
	return skill.get("name", skill_id)

func resolve_skill(skill_data) -> Dictionary:
	if typeof(skill_data) == TYPE_STRING:
		return get_skill_data(skill_data)
	if typeof(skill_data) == TYPE_DICTIONARY:
		if skill_data.has("skill_id"):
			var resolved = get_skill_data(skill_data.get("skill_id", ""))
			if !resolved.is_empty():
				return resolved
		if skill_data.has("id"):
			var resolved_by_id = get_skill_data(skill_data.get("id", ""))
			if !resolved_by_id.is_empty():
				return resolved_by_id
		return skill_data.duplicate(true)
	return {}

func resolve_skill_list(skill_values: Array) -> Array:
	var resolved_skills := []
	for skill_value in skill_values:
		var skill = resolve_skill(skill_value)
		if !skill.is_empty() and !_skill_list_has_id(resolved_skills, skill.get("id", "")):
			resolved_skills.append(skill)
	return resolved_skills

func get_skill_cost_text(skill: Dictionary, empty_text := "") -> String:
	var costs := []
	var sp_cost = int(skill.get("sp_cost", 0))
	var hp_cost = int(skill.get("hp_cost", 0))
	if sp_cost > 0:
		costs.append("SP：%d" % sp_cost)
	if hp_cost > 0:
		costs.append("HP：%d" % hp_cost)
	if costs.is_empty():
		return empty_text
	return _join_strings(costs, " ")

func get_menu_skill_cost_text(skill: Dictionary) -> String:
	var text = get_skill_cost_text(skill)
	if text == "":
		return "消費なし"
	return text.replace("SP：", "消費SP: ").replace("HP：", "消費HP: ")

func get_skill_description(skill: Dictionary) -> String:
	var target = skill.get("target", "enemy")
	var power = float(skill.get("power", 1.0))
	var element_text = _get_element_text(skill.get("element", ""))
	if skill.get("effect_type", "") == "damage_reduction":
		var turns = int(skill.get("turns", 1))
		var rate = float(skill.get("reduction_rate", 1.0))
		var percent = int(round((1.0 - rate) * 100.0))
		var text = "%dターン受けるダメージを%d%%軽減する" % [turns, percent]
		if skill.has("attack_rate"):
			var attack_percent = int(round((float(skill.get("attack_rate", 1.0)) - 1.0) * 100.0))
			text += "、攻撃力を%d%%上げる" % attack_percent
		return text
	if skill.get("effect_type", "") == "counter":
		return "攻撃されたとき防御力参照で反撃する"
	if skill.get("effect_type", "") == "howling":
		return "ハウリング状態になり、味方がダメージを与えたとき1ターンに1回だけ同じダメージを与える"
	if skill.get("effect_type", "") == "inspect":
		return "敵のステータス、残りHP、弱点を確認する"
	if skill.get("effect_type", "") == "fixed_damage":
		if target == "all_enemies":
			if skill.get("ignore_defense", false):
				return "敵全体に防御力無視の%d固定ダメージを与える" % int(skill.get("fixed_damage", 0))
			return "敵全体に%dの固定ダメージを与える" % int(skill.get("fixed_damage", 0))
		return "選択した敵1体に%dの固定ダメージを与える" % int(skill.get("fixed_damage", 0))
	if skill.get("effect_type", "") == "heal_hp":
		return "味方1人のHPを%d回復する" % int(skill.get("heal_amount", 0))
	if skill.get("effect_type", "") == "status":
		var status_name = _get_status_effect_name(skill.get("status_id", ""))
		var turns = int(skill.get("turns", -1))
		if target == "all_enemies":
			if turns > 0:
				return "敵全体を%dターン%sにする" % [turns, status_name]
			return "敵全体を%sにする" % status_name
		if turns > 0:
			return "対象を%dターン%sにする" % [turns, status_name]
		return "対象を%sにする" % status_name
	if skill.get("effect_type", "") == "party_aura":
		match skill.get("aura_id", skill.get("id", "")):
			"":
				return "効果なし"
			"high_voltage":
				return "戦闘中、味方全体が与えるダメージを+%dし、受けるダメージが+%dされる" % [
					int(skill.get("damage_bonus", 0)),
					int(skill.get("incoming_damage_bonus", 0))
				]
			"chill_down":
				var speed_modifier = int(skill.get("speed_modifier", 0))
				var defense_percent = int(round(float(skill.get("defense_rate", 1.0)) * 100.0))
				if speed_modifier < 0:
					return "戦闘中、味方全体の素早さが%d下がり、防御力が%d%%になる" % [abs(speed_modifier), defense_percent]
				return "戦闘中、味方全体の素早さが%d上がり、防御力が%d%%になる" % [speed_modifier, defense_percent]
		return "戦闘中、味方全体に効果を与える"
	if target == "enemy":
		var power_text = _format_power(power)
		if skill.get("ignore_defense", false):
			return "%s攻撃力の%s倍で防御を無視して攻撃する" % [element_text, power_text]
		return "%s攻撃力の%s倍で攻撃する" % [element_text, power_text]
	if target == "self":
		return "自分に効果を与える"
	if target == "ally":
		return "味方1人に効果を与える"
	if target == "all_enemies":
		return "敵全体に効果を与える"
	return "効果なし"

func get_battle_skill_description(skill: Dictionary) -> String:
	var cost = get_skill_cost_text(skill)
	var effect = get_skill_description(skill)
	var priority = int(skill.get("priority", 0))
	if priority > 0:
		effect = "優先度：%d/%s" % [priority, effect]
	if cost == "":
		return effect
	return "%s/%s" % [cost, effect]

func get_menu_skill_description(skill: Dictionary) -> String:
	var description = get_skill_description(skill)
	if description.ends_with("する"):
		description = description.substr(0, description.length() - 2)
	return description

func _skill_list_has_id(skill_list: Array, skill_id: String) -> bool:
	if skill_id == "":
		return false
	for skill in skill_list:
		if skill.get("id", "") == skill_id:
			return true
	return false

func _join_strings(values: Array, separator: String) -> String:
	var text := ""
	for i in range(values.size()):
		if i > 0:
			text += separator
		text += str(values[i])
	return text

func _format_power(power: float) -> String:
	if is_equal_approx(power, round(power)):
		return str(int(round(power)))
	return "%.1f" % power

func _get_status_effect_name(status_id: String) -> String:
	match status_id:
		"mental_weakness":
			return "精神虚弱"
	return status_id

func _get_element_text(element: String) -> String:
	match element:
		"fire":
			return "炎属性の"
		"electric":
			return "電気属性の"
		"ice":
			return "氷属性の"
	return ""
