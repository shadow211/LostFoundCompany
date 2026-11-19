class_name Sparkle
extends Node2D

## 找到物品时的小星光特效，0.45 秒后自毁。

var life: float = 0.0
const DURATION := 0.45

func _process(delta: float) -> void:
	life += delta
	var t := life / DURATION
	if t >= 1.0:
		queue_free()
		return
	scale = Vector2.ONE * (0.5 + t * 1.1)
	modulate.a = 1.0 - t
	queue_redraw()

func _draw() -> void:
	var col := Color(1.0, 0.85, 0.3)
	for i in 8:
		var a := TAU * float(i) / 8.0
		draw_line(Vector2(cos(a), sin(a)) * 8.0, Vector2(cos(a), sin(a)) * 30.0, col, 3.5)
	draw_circle(Vector2.ZERO, 6.0, Color(1, 0.95, 0.6))
