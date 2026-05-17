@tool
extends Area2D
class_name GenericEventArea

@export_enum("enter", "interact")
var trigger_mode := "interact"

@export var events: Array[NPCEventData] = []
@export var one_shot := false
@export var active := true
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

func _unhandled_input(event):
	if Engine.is_editor_hint():
		return
	if trigger_mode != "interact":
		return
	if !player_in_range:
		return
	if event.is_action_pressed("interact"):
		await _run_events()
		get_viewport().set_input_as_handled()

func _on_body_entered(body):
	if body.name != "Player":
		return
	player_in_range = true
	player_ref = body
	if trigger_mode == "enter":
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

func _update_shape():
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape == null:
		return
	if collision_shape.shape == null or !(collision_shape.shape is RectangleShape2D):
		collision_shape.shape = RectangleShape2D.new()
	collision_shape.shape.size = event_size
