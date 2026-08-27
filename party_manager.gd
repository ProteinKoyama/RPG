extends Node

var party_members = []
var characters = {}
const MAX_PARTY_MEMBERS := 3
var active_party_aura_skill_id := "off_vocal"

func _ready():
	load_character_database()
func load_character_database():
	var file = FileAccess.open(
		"res://data/player_characters.json",
		FileAccess.READ
	)
	var text = file.get_as_text()
	characters = JSON.parse_string(text)
func setup_party():
	pass
func get_party():
	return party_members

func set_active_party_aura_skill_id(skill_id: String):
	if skill_id == "":
		return
	active_party_aura_skill_id = skill_id

func get_active_party_aura_skill() -> Dictionary:
	if active_party_aura_skill_id == "":
		return {}
	var skill_database = _get_skill_database()
	if skill_database == null:
		return {}
	return skill_database.get_skill_data(active_party_aura_skill_id)

func get_active_party_aura_skill_id_for_battle() -> String:
	if has_available_party_aura_skill(active_party_aura_skill_id):
		return active_party_aura_skill_id
	var aura_skills = get_available_party_aura_skills()
	if aura_skills.is_empty():
		return ""
	return aura_skills[0].get("id", "")

func get_available_party_aura_skills() -> Array:
	var aura_skills := []
	for member in party_members:
		for skill in member.get_available_skills():
			if skill.get("effect_type", "") == "party_aura" and !_skill_list_has_id(aura_skills, skill.get("id", "")):
				aura_skills.append(skill)
	return aura_skills

func has_available_party_aura_skill(skill_id: String) -> bool:
	for skill in get_available_party_aura_skills():
		if skill.get("id", "") == skill_id:
			return true
	return false

func _skill_list_has_id(skill_list: Array, skill_id: String) -> bool:
	if skill_id == "":
		return false
	for skill in skill_list:
		if skill.get("id", "") == skill_id:
			return true
	return false

func _get_skill_database():
	var tree = Engine.get_main_loop()
	if !(tree is SceneTree):
		return null
	return tree.root.get_node_or_null("SkillDatabase")

func can_add_member(character_id: String) -> bool:
	if !characters.has(character_id):
		print("character not found:", character_id)
		return false
	for member in party_members:
		if member.char_id == character_id:
			print("already joined:", character_id)
			return false
	if party_members.size() >= MAX_PARTY_MEMBERS:
		print("party is full:", character_id)
		return false
	return true
func add_member(character_id) -> bool:
	if !can_add_member(character_id):
		return false
	party_members.append(
		Character.new(characters[character_id])
	)
	print("member added")
	print(party_members)
	return true
func get_character_name(character_id: String) -> String:
	if !characters.has(character_id):
		return character_id
	return characters[character_id].get("name", character_id)

func get_member_by_id(character_id: String):
	for member in party_members:
		if member.char_id == character_id:
			return member
	return null

func learn_member_skill(character_id: String, skill_id: String) -> bool:
	var member = get_member_by_id(character_id)
	if member == null:
		print("party member not found:", character_id)
		return false
	var learned_skill = member.learn_skill_by_id(skill_id)
	if learned_skill.is_empty():
		print("skill already learned or not found:", character_id, skill_id)
		return false
	return true

func remove_member(character):
	party_members.erase(character)
func heal_all_full():
	for member in party_members:
		member.heal_full()

func set_all_hp_one():
	for member in party_members:
		member.set_hp_one()
