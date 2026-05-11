extends Node

var party_members = []

func _ready():
	pass

func setup_party():
	party_members.clear()
	var hero = Character.new({
		"name":"勇者",
		"hp":100,
		"attack":20,
		"speed":10
	})
	var hello = Character.new({
		"name":"偽勇者",
		"hp":100,
		"attack":20,
		"speed":10
	})
	party_members.append(hero)
	party_members.append(hello)
	print("party setup")
func get_party():
	return party_members
func add_member(character):
	party_members.append(character)
func remove_member(character):
	party_members.erase(character)
