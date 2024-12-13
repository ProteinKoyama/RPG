extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for chars in self.get_children():
		for child in chars.get_children():
			if child is Label:
				child.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_player_interact_signal() -> void:
	pass # Replace with function body.
