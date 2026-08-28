extends Resource
class_name NPCData

@export var npc_name: String = ""
@export var portrait: Texture2D
@export var sprite_frames: SpriteFrames
@export_group("JSON Event")
@export var event_id := ""
@export_group("Resource Event (Compatibility)")
@export var event_sequence: EventSequence
@export_group("Legacy Event Data")
@export var events: Array[NPCEventData] = []
@export_group("")
@export var remove_after_events := false

func get_event_source():
	if event_id != "":
		return event_id
	if event_sequence != null:
		return event_sequence
	return events
