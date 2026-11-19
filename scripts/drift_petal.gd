class_name DriftPetal
extends Node2D

## 飘落的花瓣/叶子：缓慢下落 + 左右摇摆 + 缓慢自转，
## 落到世界底部后回到顶部重新飘，循环不停，让整个场景一直有动静。

var speed: float = 22.0
var sway_amp: float = 14.0
var sway_speed: float = 0.9
var rot_speed: float = 0.4
var col := Color(1, 0.75, 0.85)
var size: float = 7.0
var _t: float = 0.0
var _base_x: float = 0.0

func setup(p_col: Color, p_size: float, p_speed: float) -> void:
	col = p_col
	size = p_size
	speed = p_speed
	_base_x = position.x
	_t = randf() * TAU

func _process(delta: float) -> void:
	_t += delta
	position.y += speed * delta
	position.x = _base_x + sin(_t * sway_speed) * sway_amp
	rotation += rot_speed * delta
	if position.y > 1100.0:
		position.y = -20.0
		_base_x = randf_range(0.0, 1600.0)
	queue_redraw()

func _draw() -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := TAU * float(i) / 10.0
		pts.append(Vector2(cos(a) * size, sin(a) * size * 0.55))
	draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.85))
