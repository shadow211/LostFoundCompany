class_name FoundBubble
extends Node2D

## 找到瞬间：物体正上方一个橙色圆角气泡，写“找到了！”（参考原作视频），
## 静止不动，0.9 秒后淡出自毁；常驻标记由 game.gd 在反馈结束后补上。

var text: String = "找到了！"
var _life: float = 0.0
const DURATION := 0.9
const FONT_SIZE := 30

func setup(p_text: String = "找到了！") -> void:
	text = p_text

func _process(delta: float) -> void:
	_life += delta
	if _life >= DURATION:
		queue_free()
		return
	if _life > 0.65:
		modulate.a = 1.0 - (_life - 0.65) / 0.25
	queue_redraw()

func _draw() -> void:
	if text.is_empty():
		return
	var font: Font = load("res://fonts/NotoSansCJKsc-Regular.otf")
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var rect := Rect2(Vector2(-size.x * 0.5 - 18.0, -size.y - 26.0), Vector2(size.x + 36.0, size.y + 20.0))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.55, 0.1, 0.98)
	sb.set_corner_radius_all(14)
	draw_style_box(sb, rect)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10, rect.end.y - 2), Vector2(10, rect.end.y - 2), Vector2(0, rect.end.y + 12),
	]), Color(0.98, 0.55, 0.1, 0.98))
	draw_string(font, Vector2(-size.x * 0.5, -14.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
