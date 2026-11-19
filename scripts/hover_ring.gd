class_name HoverRing
extends Node2D

## 悬停光圈：鼠标停在可交互物体上时，在它周围持续脉动的金圈，
## 移开即由 game.gd 释放。本身不计时、不自毁。

var radius: float = 48.0
var _t: float = 0.0

func setup(p_radius: float) -> void:
	radius = p_radius

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 6.0)
	var r := radius + pulse * 5.0
	var alpha := 0.55 + 0.35 * pulse
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(1.0, 0.8, 0.2, alpha), 4.0)
	draw_arc(Vector2.ZERO, r * 0.82, 0, TAU, 40, Color(1.0, 0.92, 0.5, alpha * 0.7), 2.5)
