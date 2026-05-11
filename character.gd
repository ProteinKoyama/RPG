extends Node
class_name Character

var char_name: String
var max_hp: int
var hp: int
var attack: int
var speed: int

func _init(data: Dictionary):
	char_name = data.get("name", "unknown")
	max_hp = data.get("hp", 1)
	hp = max_hp
	attack = data.get("attack", 1)
	speed = data.get("speed", 1)

func is_alive() -> bool:
	return hp > 0

func take_damage(damage: int):
	hp -= damage
	if hp < 0:
		hp = 0

func attack_target(target: Character):
	var messages = []
	messages.append(name + " の攻撃！")
	target.take_damage(attack)
	messages.append(target.name + " に " + str(attack) + " ダメージ！（残りHP: " + str(target.hp) + "）")
	return messages
