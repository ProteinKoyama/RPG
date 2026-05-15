extends StaticBody2D

@export var data: NPCData
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player_in_range := false
var busy := false
var player_ref: Node2D = null
var default_sprite_frames: SpriteFrames

func _ready():
	default_sprite_frames = animated_sprite.sprite_frames
	refresh_sprite()
	face_direction("front")

func refresh_sprite():
	if data != null and data.sprite_frames != null:
		animated_sprite.sprite_frames = data.sprite_frames
	elif default_sprite_frames != null:
		animated_sprite.sprite_frames = default_sprite_frames
	animated_sprite.show()
	animated_sprite.visible = true
	animated_sprite.modulate = Color.WHITE

func _unhandled_input(event):
	if PlayerManager.in_battle:
		return
	if !player_in_range:
		return
	if busy:
		return
	if EventManager.dialog_visible:
		return

	if event.is_action_pressed("interact"):
		busy = true
		if player_ref != null:
			face_position(player_ref.global_position)
		print("pressed interact")
		if data == null or data.events.is_empty():
			print("NPC event is empty")
			busy = false
			get_viewport().set_input_as_handled()
			return
		await EventManager.start_cutscene(data.events)
		if data != null and data.remove_after_events:
			queue_free()
			return
		refresh_sprite()
		face_direction("front")
		busy = false
		get_viewport().set_input_as_handled()

func face_position(target_position: Vector2):
	var delta = target_position - global_position
	if abs(delta.x) > abs(delta.y):
		if delta.x > 0:
			face_direction("right")
		else:
			face_direction("left")
	else:
		if delta.y > 0:
			face_direction("front")
		else:
			face_direction("back")

func face_direction(direction: String):
	var animation_name = direction
	if direction == "front":
		animation_name = "default"
	if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.animation = animation_name
		animated_sprite.stop()

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		player_ref = body

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		player_ref = null
		busy = false
