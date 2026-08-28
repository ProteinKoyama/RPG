extends Resource
class_name EventSequence

@export var events: Array[EventCommand] = []

func is_empty() -> bool:
	return events.is_empty()
