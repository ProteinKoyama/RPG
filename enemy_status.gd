extends Control

@onready var enemy_sprite = $VBoxContainer/EnemySprite
@onready var name_label = $VBoxContainer/NameLabel
@onready var hp_label = $VBoxContainer/HPLabel
@onready var effect_label = $VBoxContainer/EffectLabel
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
	await get_tree().process_frame
	_update_target_cursor_position()

func setup(enemy):
	enemy_ref = enemy
	name_label.text = enemy.char_name
	refresh_effects()
	if enemy.image_path != "":
		enemy_sprite.texture = load(enemy.image_path)
	if death_mat:
		death_mat.set_shader_parameter("reveal", 1.0)
	target_cursor.visible = false
	modulate = Color.WHITE
	scale = Vector2.ONE
	is_dying = false
	await get_tree().process_frame
	_update_target_cursor_position()

func refresh_effects():
	refresh_hp()
	effect_label.text = _get_effect_text(enemy_ref)

func refresh_hp() -> void:
	if enemy_ref == null:
		hp_label.text = ""
		return
	hp_label.text = "%d/%d" % [enemy_ref.hp, enemy_ref.max_hp]

func _get_effect_text(enemy) -> String:
	if enemy == null or !enemy.has_method("get_active_effect_labels"):
		return ""
	var labels = enemy.get_active_effect_labels()
	if labels.is_empty():
		return ""
	return _join_strings(labels, " / ")

func _join_strings(values: Array, separator: String) -> String:
	var text := ""
	for i in range(values.size()):
		if i > 0:
			text += separator
		text += str(values[i])
	return text

func _unhandled_input(event):
	pass

func enable_target_select():
	target_select_enabled = true
	focus_mode = Control.FOCUS_ALL
	_update_target_cursor_position()
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

func _update_target_cursor_position():
	if enemy_sprite == null or target_cursor == null:
		return
	var sprite_global_rect = enemy_sprite.get_global_rect()
	var sprite_top_center_global = sprite_global_rect.position + Vector2(sprite_global_rect.size.x / 2.0, 0.0)
	var sprite_top_center = get_global_transform_with_canvas().affine_inverse() * sprite_top_center_global
	var cursor_size = target_cursor.size
	target_cursor.position = sprite_top_center - Vector2(cursor_size.x / 2.0, cursor_size.y + 8.0)

func _on_focus_entered():
	if target_select_enabled and !is_dying:
		_update_target_cursor_position()
		target_cursor.visible = true
		modulate = Color(1.25, 1.25, 1.25, 1.0)

func _on_focus_exited():
	target_cursor.visible = false
	if !is_dying:
		modulate = Color.WHITE
