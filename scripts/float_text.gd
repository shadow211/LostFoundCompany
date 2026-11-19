class_name FloatText
extends Node2D

## 飘字：点中彩蛋/找到物品时，在物体上方飘起一句字，约 1 秒后淡出自毁。
## 例如猫 "哈～"、鸟 "啾啾♪"、找到物品 "找到了！"。

var text: String = ""
var col := Color(0.45, 0.3, 0.15)
var _life: float = 0.0
const DURATION := 1.0
const FONT_SIZE := 30

func setup(p_text: String, p_col: Color = Color(0.45, 0.3, 0.15)) -> void:
	text = p_text
	col = p_col

func _process(delta: float) -> void:
	_life += delta
	if _life >= DURATION:
		queue_free()
		return
	position.y -= delta * 34.0
	modulate.a = 1.0 - _life / DURATION
	queue_redraw()

func _draw() -> void:
	if text.is_empty():
		return
	var font: Font = load("res://fonts/NotoSansCJKsc-Regular.otf")
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var pos := Vector2(-size.x * 0.5, 0)
	# 白色描边衬底，保证在任何底色上都看得清
	draw_string(font, pos + Vector2(2, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(1, 1, 1, 0.9))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, col)
