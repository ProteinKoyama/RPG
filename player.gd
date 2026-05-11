extends CharacterBody2D

@export var speed = 200
var screen_size
var character_size= Vector2.ZERO
var character_directions:String
var key_detected_flag = false
var can_move = PlayerManager.can_move
func _ready():
	screen_size = get_viewport_rect().size

func _process(delta):
	var velocity = Vector2.ZERO
	can_move = PlayerManager.can_move
	if can_move:
		if Input.is_action_pressed("move_right"):
			velocity.x += 1
			$AnimationSprite2D.animation = "walk_right"
			character_directions = "right"
		if Input.is_action_pressed("move_left"):
			velocity.x -= 1
			$AnimationSprite2D.animation = "walk_left"
			character_directions = "left"
		if Input.is_action_pressed("move_up"):
			$AnimationSprite2D.animation = "back_walk"
			velocity.y -= 1
			character_directions = "back"
		if Input.is_action_pressed("move_down"):
			$AnimationSprite2D.animation = "walk_front"
			velocity.y += 1
			character_directions = "front"
		if velocity.length() > 0:
			velocity = velocity.normalized() * speed
			$AnimationSprite2D.play()
		else:
			$AnimationSprite2D.animation = "default"
			if character_directions == "right":
				$AnimationSprite2D.animation = "right"
			if character_directions == "left":
				$AnimationSprite2D.animation = "left"
			if character_directions == "back":
				$AnimationSprite2D.animation = "back"
		position += velocity * delta
	#position = position.clamp(Vector2.ZERO, screen_size)
	velocity = move_and_slide()
	if Input.is_action_just_pressed("interact") and !key_detected_flag:
		pass
