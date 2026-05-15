extends Control

@onready var enemy_sprite = $VBoxContainer/EnemySprite
@onready var name_label = $VBoxContainer/NameLabel
@onready var target_cursor = $TargetCursor

var enemy_ref
var target_select_enabled := false
var is_dying := false
var death_mat: ShaderMaterial

signal target_selected(enemy)

const WIPE_SHADER := """
shader_type canvas_item;
uniform float reveal : hint_range(0.0, 1.0) = 1.0;
void fragment() {
	if (UV.y < (1.0 - reveal)) {
		discard;
	}
}
"""

func _ready():
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)

	var sh := Shader.new()
	sh.code = WIPE_SHADER
	death_mat = ShaderMaterial.new()
	death_mat.shader = sh
	enemy_sprite.material = death_mat
	death_mat.set_shader_parameter("reveal", 1.0)

	target_cursor.visible = false

func setup(enemy):
	enemy_ref = enemy
	name_label.text = enemy.char_name
	if enemy.image_path != "":
		enemy_sprite.texture = load(enemy.image_path)
	if death_mat:
		death_mat.set_shader_parameter("reveal", 1.0)
	target_cursor.visible = false
	modulate = Color.WHITE
	scale = Vector2.ONE
	is_dying = false

func _unhandled_input(event):
	pass

func enable_target_select():
	target_select_enabled = true
	focus_mode = Control.FOCUS_ALL
	grab_focus()

func disable_target_select():
	target_select_enabled = false
	focus_mode = Control.FOCUS_NONE
	target_cursor.visible = false
	modulate = Color.WHITE
	scale = Vector2.ONE

func play_death_animation():
	if is_dying:
		return
	is_dying = true
	target_select_enabled = false
	focus_mode = Control.FOCUS_NONE
	target_cursor.visible = false
	modulate = Color.WHITE
	scale = Vector2.ONE

	var tween := create_tween()
	tween.tween_method(_set_reveal, 1.0, 0.0, 0.35)
	tween.tween_callback(queue_free)

func _set_reveal(v: float) -> void:
	if death_mat:
		death_mat.set_shader_parameter("reveal", v)

func _on_focus_entered():
	if target_select_enabled and !is_dying:
		target_cursor.visible = true

func _on_focus_exited():
	target_cursor.visible = false
