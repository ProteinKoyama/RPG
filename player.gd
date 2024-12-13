extends CharacterBody2D

signal interact_signal

@export var speed = 200
var screen_size
var character_size= Vector2.ZERO
var key_detected_flag = false
var moving_up_flag = false

func _ready():
	screen_size = get_viewport_rect().size
	
func _process(delta):
	var velocity = Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		velocity.x += 1
		$AnimationSprite2D.animation = "walk_right"
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
		$AnimationSprite2D.animation = "walk_left"
	if Input.is_action_pressed("move_up"):
		$AnimationSprite2D.animation = "behind_walk"
		velocity.y -= 1
		moving_up_flag = true
	if Input.is_action_pressed("move_down"):
		$AnimationSprite2D.animation = "walk_front"
		velocity.y += 1
		moving_up_flag = false
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimationSprite2D.play()
	else:
		$AnimationSprite2D.animation = "default"
		if moving_up_flag:
			$AnimationSprite2D.animation = "behind"
		$AnimationSprite2D.stop()
		
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)

	if Input.is_action_pressed("interact") and !key_detected_flag:
			print("interact")
			emit_signal("interact")
			$InteractTimer.start()
			key_detected_flag = true

func _on_area_2d_area_entered(area: Area2D) -> void:
	print("test")


func _on_interact_timer_timeout() -> void:
	if key_detected_flag:
		print("timeout")
	key_detected_flag = false
