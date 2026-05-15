extends Node

var party_members = []
var characters = {}

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
func add_member(character_id):
	if !characters.has(character_id):
		print("character not found:", character_id)
		return
	for member in party_members:
		if member.char_id == character_id:
			print("already joined:", character_id)
			return
	party_members.append(
		Character.new(characters[character_id])
	)
	print("member added")
	print(party_members)
func remove_member(character):
	party_members.erase(character)
func heal_all_full():
	for member in party_members:
		member.heal_full()

func set_all_hp_one():
	for member in party_members:
		member.set_hp_one()
