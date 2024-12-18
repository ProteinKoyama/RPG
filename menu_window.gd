extends CanvasLayer


func _ready() -> void:
	$Panel.hide()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("open_menu"):
		$Panel.visible = !$Panel.visible
