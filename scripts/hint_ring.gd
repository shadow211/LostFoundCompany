class_name HintRing
extends Node2D

## 提示光圈：在目标位置脉冲 2.5 秒后自毁。

var life: float = 0.0
const DURATION := 2.5

func _process(delta: float) -> void:
	life += delta
	if life >= DURATION:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(life * 10.0)
	var radius := 40.0 + pulse * 10.0
	var alpha := clampf(1.0 - life / DURATION, 0.0, 1.0) * (0.55 + 0.45 * pulse)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(1.0, 0.8, 0.2, alpha), 5.0)
	draw_arc(Vector2.ZERO, radius * 0.7, 0, TAU, 40, Color(1.0, 0.9, 0.4, alpha * 0.8), 3.0)
