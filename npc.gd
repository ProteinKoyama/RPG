extends Area2D

@export var data: NPCData
@onready var sprite: Sprite2D = $Sprite2D

var player_in_range := false
var busy := false

func _ready():
	if data != null and data.portrait != null:
		sprite.texture = data.portrait

func _unhandled_input(event):
	if !player_in_range:
		return
	if busy:
		return
	if EventManager.dialog_visible:
		return

	if event.is_action_pressed("interact"):
		busy = true
		print("pressed interact")
		await EventManager.start_cutscene(data.events)
		busy = false
		get_viewport().set_input_as_handled()

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		busy = false
