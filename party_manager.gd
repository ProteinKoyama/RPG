extends Node

var party_members = []
var characters = {}
const MAX_PARTY_MEMBERS := 3

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
func remove_member(character):
	party_members.erase(character)
func heal_all_full():
	for member in party_members:
		member.heal_full()

func set_all_hp_one():
	for member in party_members:
		member.set_hp_one()
