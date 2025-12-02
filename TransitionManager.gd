# TransitionManager.gd
extends CanvasLayer

var fade_rect: ColorRect

func _ready() -> void:
	# 画面を覆う黒い矩形を作る
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0) # 初期は透明（フェードイン済み相当）
	fade_rect.size = get_viewport().get_visible_rect().size
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_rect)

	# ビューポートサイズが変わる可能性があるので調整
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed"))

	# 最初はフェードイン（あるいは不要ならコメントアウト）
	# await fade_in()  # 起動時にフェードインしたければ await で呼ぶ

func _on_viewport_size_changed() -> void:
	fade_rect.size = get_viewport().get_visible_rect().size


# フェードアウト（暗転）。待機可能。
func fade_out(duration: float = 0.4) -> void:
	var tw = create_tween()
	# ColorRect の色のアルファ成分を 1.0 へ
	tw.tween_property(fade_rect, "color:a", 1.0, duration)
	await tw.finished


# フェードイン（復帰）。待機可能。
func fade_in(duration: float = 0.4) -> void:
	var tw = create_tween()
	# ColorRect の色のアルファ成分を 0.0 へ
	tw.tween_property(fade_rect, "color:a", 0.0, duration)
	await tw.finished
