class_name FoundRing
extends Node2D

## 找到瞬间：亮绿圈立刻出现（参考原作视频里的样式），
## 0.12 秒弹出、停留、最后 0.25 秒淡出，0.9 秒后自毁。
## 常驻的绿圈✓标记由 game.gd 在反馈结束后补上。

var radius: float = 60.0
var _life: float = 0.0
const DURATION := 0.9

func setup(p_radius: float) -> void:
	radius = p_radius

func _process(delta: float) -> void:
	_life += delta
	if _life >= DURATION:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var pop := clampf(_life / 0.12, 0.0, 1.0)
	var r := radius * (0.85 + 0.15 * pop)
	var alpha := 1.0
	if _life > 0.65:
		alpha = 1.0 - (_life - 0.65) / 0.25
	draw_arc(Vector2.ZERO, r, 0, TAU, 64, Color(0.25, 0.95, 0.3, alpha), 7.0)
	draw_arc(Vector2.ZERO, r * 0.86, 0, TAU, 56, Color(0.65, 1.0, 0.5, alpha * 0.8), 3.0)
	for i in 8:
		var a := TAU * float(i) / 8.0 + 0.4
		draw_circle(Vector2(cos(a), sin(a)) * (r + 11.0), 3.5, Color(0.6, 1.0, 0.4, alpha))
