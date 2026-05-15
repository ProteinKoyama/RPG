extends RefCounted
class_name Character
var char_id: String = ""
var char_name: String
var max_hp: int
var hp: int
var attack: int
var defense: int
var speed: int
var image_path:String
var is_defending := false

func _init(data: Dictionary):
	char_id = data.get("id", "")
	char_name = data.get("name", "unknown")
	max_hp = data.get("hp", 1)
	hp = max_hp
	attack = data.get("attack", 1)
	defense = data.get("defense", 1)
	speed = data.get("speed", 1)
	image_path = data.get("image","")
	
func is_alive() -> bool:
	return hp > 0

func start_defense():
	is_defending = true
func clear_defense():
	is_defending = false
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
	
func heal_full():
	hp = max_hp
func set_hp_one():
	hp = 1
