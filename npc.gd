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

func _exit_tree():
	if player_in_range:
		EventManager.unregister_npc_interaction()

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
		EventManager.begin_npc_event()
		if player_ref != null:
			face_position(player_ref.global_position)
		print("pressed interact")
		var event_source = data.get_event_source() if data != null else null
		if data == null or _is_event_source_empty(event_source):
			print("NPC event is empty")
			EventManager.end_npc_event()
			busy = false
			get_viewport().set_input_as_handled()
			return
		await EventManager.start_cutscene(event_source)
		if data != null and data.remove_after_events:
			EventManager.end_npc_event()
			queue_free()
			return
		refresh_sprite()
		face_direction("front")
		EventManager.end_npc_event()
		busy = false
		get_viewport().set_input_as_handled()

func _is_event_source_empty(event_source) -> bool:
	if event_source is String or event_source is StringName:
		return String(event_source).is_empty()
	if event_source is EventSequence:
		return event_source.is_empty()
	return event_source == null or event_source.is_empty()

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

func move_to_position(target_position: Vector2, speed := 120.0) -> void:
	face_position(target_position)
	if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(animated_sprite.animation):
		animated_sprite.play()
	var duration: float = global_position.distance_to(target_position) / maxf(float(speed), 1.0)
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_position, duration)
	await tween.finished
	animated_sprite.stop()

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		player_ref = body
		EventManager.register_npc_interaction()

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		player_ref = null
		busy = false
		EventManager.unregister_npc_interaction()
