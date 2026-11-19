class_name ItemIcon
extends Control

## 清单里的物品小图标，复用 ItemDraw 绘制。

var kind: String = "apple"
var col: Color = Color.RED

func setup(p_kind: String, p_color_key: String) -> void:
	kind = p_kind
	col = ItemDraw.COLORS[p_color_key]
	custom_minimum_size = Vector2(44, 44)
	queue_redraw()

func _draw() -> void:
	ItemDraw.draw_item(self, kind, col, size * 0.5, 15.0)
