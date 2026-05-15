extends Resource
class_name NPCData

@export var npc_name: String = ""
@export var portrait: Texture2D
@export var sprite_frames: SpriteFrames
@export var events: Array[NPCEventData] = []
@export var remove_after_events := false
