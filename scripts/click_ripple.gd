class_name ClickRipple
extends Node2D

## 点击涟漪：扩散的圆环 + 淡出，任意点击都有可见反馈。
## 颜色/半径/时长可配：找到=绿、彩蛋=白、点空=淡红。

var color := Color(1, 1, 1, 0.9)
var max_r := 40.0
var duration := 0.35
var _t := 0.0

func setup(p_color: Color, p_max_r: float, p_duration: float) -> void:
	color = p_color
	max_r = p_max_r
	duration = p_duration

func _process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var k := clampf(_t / duration, 0.0, 1.0)
	var r := max_r * (0.25 + 0.75 * k)
	var a := color.a * (1.0 - k)
	draw_arc(Vector2.ZERO, r, 0, TAU, 40, Color(color, a), 4.0)
	draw_arc(Vector2.ZERO, r * 0.6, 0, TAU, 32, Color(color, a * 0.7), 2.5)
