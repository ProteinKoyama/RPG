@tool
extends Area2D
class_name GenericEventArea

@export_enum("enter", "interact")
var trigger_mode := "interact"

@export var events: Array[NPCEventData] = []
@export var one_shot := false
@export var active := true
@export var disable_if_flag_key := ""
@export var disable_if_flag_value := true
@export var trigger_animation_node_path: NodePath
@export var trigger_animation_name := ""
@export var event_size := Vector2(96, 96):
	set(value):
		event_size = value
		_update_shape()

var player_in_range := false
var player_ref: Node2D = null
var busy := false
var triggered := false

func _ready():
	_update_shape()
	if Engine.is_editor_hint():
		return
	if !body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if !body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	await get_tree().physics_frame
	if trigger_mode == "enter":
		await _run_for_overlapping_player()

func _unhandled_input(event):
	if Engine.is_editor_hint():
		return
	if trigger_mode != "interact":
		return
	if !player_in_range:
		return
	if event.is_action_pressed("interact"):
		if _is_npc_blocking():
			return
		await _run_events()
		get_viewport().set_input_as_handled()

func _on_body_entered(body):
	if body.name != "Player":
		return
	player_in_range = true
	player_ref = body
	if trigger_mode == "enter":
		await get_tree().physics_frame
		if !player_in_range:
			return
		await _run_events()

func _on_body_exited(body):
	if body != player_ref and body.name != "Player":
		return
	player_in_range = false
	player_ref = null

func _run_events():
	if !active:
		return
	if busy:
		return
	if triggered and one_shot:
		return
	var player_manager = _get_autoload("PlayerManager")
	var event_manager = _get_autoload("EventManager")
	if player_manager != null and player_manager.in_battle:
		return
	if event_manager != null and _is_disabled_by_flag(event_manager):
		return
	if event_manager != null and event_manager.has_method("is_npc_event_blocking"):
		if event_manager.is_npc_event_blocking():
			return
	if event_manager != null and event_manager.dialog_visible:
		return

	busy = true
	if events.is_empty():
		print("generic event area events are empty")
		busy = false
		return

	if event_manager == null:
		print("EventManager not found")
		busy = false
		return
	_play_trigger_animation()
	await event_manager.start_cutscene(events)
	triggered = true
	if one_shot:
		active = false
	busy = false

func _get_autoload(node_name: String):
	var tree = Engine.get_main_loop()
	if !(tree is SceneTree):
		return null
	return tree.root.get_node_or_null(node_name)

func _run_for_overlapping_player() -> void:
	for body in get_overlapping_bodies():
		if body.name != "Player":
			continue
		player_in_range = true
		player_ref = body
		await _run_events()
		return

func _is_disabled_by_flag(event_manager) -> bool:
	if disable_if_flag_key == "":
		return false
	if !event_manager.has_method("get_flag"):
		return false
	return event_manager.get_flag(disable_if_flag_key) == disable_if_flag_value

func _is_npc_blocking() -> bool:
	var event_manager = _get_autoload("EventManager")
	if event_manager == null:
		return false
	if !event_manager.has_method("is_npc_event_blocking"):
		return false
	return event_manager.is_npc_event_blocking()

func _play_trigger_animation() -> void:
	if trigger_animation_node_path == NodePath("") or trigger_animation_name == "":
		return
	var target = _get_animation_target(trigger_animation_node_path)
	if target == null:
		print("trigger animation target not found:", trigger_animation_node_path)
		return
	if trigger_animation_name == "face_player":
		if target.has_method("face_position") and player_ref != null:
			target.face_position(player_ref.global_position)
		return
	if target.has_method("face_direction"):
		target.face_direction(trigger_animation_name)
		return
	var animated_sprite = target
	if !(animated_sprite is AnimatedSprite2D):
		animated_sprite = target.get_node_or_null("AnimatedSprite2D")
	if animated_sprite == null:
		print("trigger animation sprite not found:", trigger_animation_node_path)
		return
	if animated_sprite.sprite_frames == null:
		print("trigger animation sprite frames not found:", trigger_animation_node_path)
		return
	if !animated_sprite.sprite_frames.has_animation(trigger_animation_name):
		print("trigger animation not found:", trigger_animation_name)
		return
	animated_sprite.animation = trigger_animation_name
	animated_sprite.stop()

func _get_animation_target(target_path: NodePath):
	var target = get_node_or_null(target_path)
	if target != null:
		return target
	var parent_node = get_parent()
	if parent_node != null:
		target = parent_node.get_node_or_null(target_path)
		if target != null:
			return target
	var tree = Engine.get_main_loop()
	if tree is SceneTree and tree.current_scene != null:
		return tree.current_scene.get_node_or_null(target_path)
	return null

func _update_shape():
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape == null:
		return
	if collision_shape.shape == null or !(collision_shape.shape is RectangleShape2D):
		collision_shape.shape = RectangleShape2D.new()
	collision_shape.shape.size = event_size
