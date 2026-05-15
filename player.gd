extends CharacterBody2D

@export var speed = 200
var screen_size
var character_size= Vector2.ZERO
var character_directions:String
var key_detected_flag = false
var can_move = PlayerManager.can_move
func _ready():
	screen_size = get_viewport_rect().size

func stop_movement_animation():
	velocity = Vector2.ZERO
	$AnimationSprite2D.stop()
	match character_directions:
		"right":
			$AnimationSprite2D.animation = "right"
		"left":
			$AnimationSprite2D.animation = "left"
		"back":
			$AnimationSprite2D.animation = "back"
		_:
			$AnimationSprite2D.animation = "default"

func _physics_process(_delta):
	var input_velocity = Vector2.ZERO
	can_move = PlayerManager.can_move
	if can_move:
		if Input.is_action_pressed("move_right"):
			input_velocity.x += 1
			$AnimationSprite2D.animation = "walk_right"
			character_directions = "right"
		if Input.is_action_pressed("move_left"):
			input_velocity.x -= 1
			$AnimationSprite2D.animation = "walk_left"
			character_directions = "left"
		if Input.is_action_pressed("move_up"):
			$AnimationSprite2D.animation = "back_walk"
			input_velocity.y -= 1
			character_directions = "back"
		if Input.is_action_pressed("move_down"):
			$AnimationSprite2D.animation = "walk_front"
			input_velocity.y += 1
			character_directions = "front"
		if input_velocity.length() > 0:
			input_velocity = input_velocity.normalized() * speed
			$AnimationSprite2D.play()
		else:
			$AnimationSprite2D.animation = "default"
			if character_directions == "right":
				$AnimationSprite2D.animation = "right"
			if character_directions == "left":
				$AnimationSprite2D.animation = "left"
			if character_directions == "back":
				$AnimationSprite2D.animation = "back"
		velocity = input_velocity
	else:
		velocity = Vector2.ZERO
	#position = position.clamp(Vector2.ZERO, screen_size)
	move_and_slide()

func _process(_delta):
	if Input.is_action_just_pressed("interact") and !key_detected_flag:
		pass
func _unhandled_input(event):
	if PlayerManager.in_battle:
		return
	if MenuManager.is_menu_open():
		return
	if event.is_action_pressed("menu"):
		if MenuManager.is_menu_open():
			return
		if event.is_action_pressed("menu"):
			MenuManager.open_menu()
			get_viewport().set_input_as_handled()
		if PlayerManager.can_move:
			MenuManager.open_menu()
			get_viewport().set_input_as_handled()
