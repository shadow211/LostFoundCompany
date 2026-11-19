class_name FoundMarker
extends Node2D

## 找到物品后留下的绿色圈 + 对勾标记（常驻）。

func _draw() -> void:
	var col := Color(0.35, 0.85, 0.35, 0.95)
	draw_arc(Vector2.ZERO, 40.0, 0, TAU, 48, col, 6.0)
	draw_arc(Vector2.ZERO, 40.0, 0, TAU, 48, Color(0.1, 0.4, 0.1, 0.9), 2.0)
	draw_line(Vector2(-16, 0), Vector2(-5, 12), col, 7.0)
	draw_line(Vector2(-5, 12), Vector2(18, -14), col, 7.0)
