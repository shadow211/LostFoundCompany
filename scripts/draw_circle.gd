class_name DrawCircle
extends Node2D

## 画笔画圈：找到物品时，像拿笔画圈一样，一笔把物品圈出来。
## 0.55 秒内从顶部起笔顺时针画完，线略带手绘抖动，笔尖有个小圆点，
## 画完自毁；常驻的绿圈✓标记由 game.gd 在画完后补上。

var radius: float = 60.0
var _life: float = 0.0
const DURATION := 0.55
const PEN := Color(0.2, 0.68, 0.28)

func setup(p_radius: float) -> void:
	radius = p_radius

func _process(delta: float) -> void:
	_life += delta
	if _life >= DURATION:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var progress := clampf(_life / DURATION, 0.0, 1.0)
	var sweep := TAU * progress
	var start := -PI * 0.5
	var pts := PackedVector2Array()
	var steps := maxi(2, int(sweep / 0.09))
	for i in range(steps + 1):
		var a := start + sweep * float(i) / float(steps)
		var wobble := sin(a * 6.0) * 2.5
		pts.append(Vector2(cos(a), sin(a)) * (radius + wobble))
	if pts.size() >= 2:
		draw_polyline(pts, PEN, 5.0, true)
		# 笔尖
		draw_circle(pts[pts.size() - 1], 6.0, PEN)
