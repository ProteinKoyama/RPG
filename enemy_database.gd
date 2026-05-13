extends Node
var enemies = {}
func _ready():
	load_enemy_data()

func load_enemy_data():
	var file = FileAccess.open(
		"res://data/enemies.json",
		FileAccess.READ
	)

	var text = file.get_as_text()
	enemies = JSON.parse_string(text)
func get_enemy_data(id):
	return enemies[id]
