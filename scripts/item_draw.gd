class_name ItemDraw
extends RefCounted

## 全部物品用代码矢量绘制：扁平上色 + 深色描边，绘本手绘风（原创图形）。
## draw_item(ci, kind, col, center, r)：以 center 为中心、r 为半径绘制。

const INK := Color(0.27, 0.2, 0.16)

const KIND_NAMES := {
	"apple": "苹果", "key": "钥匙", "book": "书", "cup": "杯子",
	"hat": "帽子", "umbrella": "雨伞", "sock": "袜子", "scissors": "剪刀",
	"candle": "蜡烛", "clock": "时钟", "fish": "小鱼", "flower": "小花",
	"star": "星星", "mushroom": "蘑菇", "glasses": "眼镜", "balloon": "气球",
	"teapot": "茶壶", "boot": "靴子", "gift": "礼物盒", "lamp": "台灯",
}

const COLORS := {
	"红": Color(0.88, 0.32, 0.28), "橙": Color(0.95, 0.58, 0.22),
	"黄": Color(0.97, 0.8, 0.28), "绿": Color(0.42, 0.72, 0.38),
	"蓝": Color(0.36, 0.57, 0.88), "紫": Color(0.64, 0.47, 0.82),
	"粉": Color(0.96, 0.65, 0.76), "棕": Color(0.6, 0.43, 0.28),
	"金": Color(0.88, 0.68, 0.24), "银": Color(0.76, 0.78, 0.82),
	"白": Color(0.95, 0.94, 0.91), "黑": Color(0.26, 0.26, 0.29),
}

const ALL_KINDS: Array[String] = [
	"apple", "key", "book", "cup", "hat", "umbrella", "sock", "scissors",
	"candle", "clock", "fish", "flower", "star", "mushroom", "glasses",
	"balloon", "teapot", "boot", "gift", "lamp",
]

static func color_keys() -> Array:
	return COLORS.keys()

static func display_name(kind: String, color_key: String) -> String:
	return color_key + "色的" + KIND_NAMES.get(kind, kind)

# ---------- 带描边的基础形状 ----------
static func _oc(ci: CanvasItem, c: Vector2, r: float, col: Color, w: float) -> void:
	ci.draw_circle(c, r, col)
	ci.draw_arc(c, r, 0, TAU, 32, INK, w)

static func _oe(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, w: float, n: int = 28) -> void:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)
	var line := PackedVector2Array(pts)
	line.append(pts[0])
	ci.draw_polyline(line, INK, w)

static func _or(ci: CanvasItem, rect: Rect2, col: Color, w: float) -> void:
	ci.draw_rect(rect, col)
	ci.draw_rect(rect, INK, false, w)

static func _op(ci: CanvasItem, offs: Array, c: Vector2, r: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for o in offs:
		pts.append(c + Vector2(o[0], o[1]) * r)
	ci.draw_colored_polygon(pts, col)
	var line := PackedVector2Array(pts)
	line.append(pts[0])
	ci.draw_polyline(line, INK, w)

static func _hd(ci: CanvasItem, c: Vector2, r: float, col: Color, w: float, n: int = 24) -> void:
	var pts := PackedVector2Array()
	pts.append(c + Vector2(-r, 0))
	for i in range(n + 1):
		var a := PI + PI * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * r, sin(a) * r))
	pts.append(c + Vector2(r, 0))
	ci.draw_colored_polygon(pts, col)
	var line := PackedVector2Array(pts)
	ci.draw_polyline(line, INK, w)

static func draw_item(ci: CanvasItem, kind: String, col: Color, c: Vector2, r: float) -> void:
	var dark := col.darkened(0.22)
	var w := r * 0.11
	var ink := INK
	match kind:
		"apple":
			_oc(ci, c + Vector2(0, 0.08) * r, r * 0.8, col, w)
			ci.draw_line(c + Vector2(0, -0.5) * r, c + Vector2(0.1, -0.95) * r, Color(0.4, 0.26, 0.12), w)
			_oe(ci, c + Vector2(0.36, -0.74) * r, r * 0.3, r * 0.14, Color(0.42, 0.72, 0.38), w * 0.8)
			ci.draw_circle(c + Vector2(-0.3, -0.18) * r, r * 0.18, Color(1, 1, 1, 0.35))
		"key":
			ci.draw_arc(c + Vector2(-0.35, 0) * r, r * 0.42, 0, TAU, 24, ink, w * 1.9)
			ci.draw_arc(c + Vector2(-0.35, 0) * r, r * 0.42, 0, TAU, 24, col, w * 1.2)
			ci.draw_line(c + Vector2(-0.02, 0) * r, c + Vector2(0.88, 0) * r, ink, w * 1.9)
			ci.draw_line(c + Vector2(-0.02, 0) * r, c + Vector2(0.88, 0) * r, col, w * 1.2)
			ci.draw_line(c + Vector2(0.55, 0) * r, c + Vector2(0.55, 0.34) * r, ink, w * 1.7)
			ci.draw_line(c + Vector2(0.55, 0) * r, c + Vector2(0.55, 0.34) * r, col, w)
			ci.draw_line(c + Vector2(0.88, 0) * r, c + Vector2(0.88, 0.48) * r, ink, w * 1.7)
			ci.draw_line(c + Vector2(0.88, 0) * r, c + Vector2(0.88, 0.48) * r, col, w)
		"book":
			_or(ci, Rect2(c + Vector2(-0.6, -0.78) * r, Vector2(1.24, 1.6) * r), col, w)
			ci.draw_rect(Rect2(c + Vector2(-0.44, -0.66) * r, Vector2(1.06, 1.36) * r), Color(0.98, 0.96, 0.92))
			ci.draw_line(c + Vector2(-0.44, -0.78) * r, c + Vector2(-0.44, 0.82) * r, dark, w)
			ci.draw_line(c + Vector2(-0.2, -0.3) * r, c + Vector2(0.42, -0.3) * r, Color(0.62, 0.62, 0.64), w * 0.9)
			ci.draw_line(c + Vector2(-0.2, 0.05) * r, c + Vector2(0.42, 0.05) * r, Color(0.62, 0.62, 0.64), w * 0.9)
		"cup":
			_op(ci, [[-0.55, -0.5], [0.55, -0.5], [0.42, 0.6], [-0.42, 0.6]], c, r, col, w)
			_oe(ci, c + Vector2(0, -0.5) * r, r * 0.55, r * 0.14, Color(0.4, 0.24, 0.12), w * 0.7)
			ci.draw_arc(c + Vector2(0.62, 0.02) * r, r * 0.3, -PI / 2.0, PI / 2.0, 16, ink, w)
			ci.draw_line(c + Vector2(-0.72, 0.78) * r, c + Vector2(0.72, 0.78) * r, ink, w)
		"hat":
			_oe(ci, c + Vector2(0, 0.14) * r, r * 0.95, r * 0.18, dark, w)
			var hat_pts := PackedVector2Array()
			hat_pts.append(c + Vector2(-0.62, 0.14) * r)
			for i in range(21):
				var a := PI + PI * float(i) / 20.0
				hat_pts.append(c + Vector2(cos(a) * 0.62, 0.14 + sin(a) * 0.62) * r)
			hat_pts.append(c + Vector2(0.62, 0.14) * r)
			ci.draw_colored_polygon(hat_pts, col)
			var hat_line := PackedVector2Array(hat_pts)
			ci.draw_polyline(hat_line, ink, w)
			ci.draw_rect(Rect2(c + Vector2(-0.62, -0.04) * r, Vector2(1.24, 0.18) * r), dark)
		"umbrella":
			_hd(ci, c + Vector2(0, 0.12) * r, r * 0.95, col, w)
			for i in range(-1, 2):
				ci.draw_line(c + Vector2(0, 0.12) * r, c + Vector2(0.6 * i, -0.55) * r + Vector2(0, 0.12) * r, ink, w * 0.5)
			ci.draw_line(c + Vector2(0, -0.82) * r, c + Vector2(0, 0.55) * r, ink, w)
			ci.draw_arc(c + Vector2(0.17, 0.55) * r, r * 0.17, PI, TAU, 12, ink, w)
			_oc(ci, c + Vector2(0, -0.86) * r, r * 0.08, dark, w * 0.7)
		"sock":
			_op(ci, [[-0.3, -0.85], [0.3, -0.85], [0.3, 0.08], [0.78, 0.44], [0.74, 0.8], [0.24, 0.84], [-0.08, 0.42], [-0.3, 0.22]], c, r, col, w)
			ci.draw_rect(Rect2(c + Vector2(-0.3, -0.85) * r, Vector2(0.6, 0.22) * r), Color(0.97, 0.96, 0.93))
			ci.draw_rect(Rect2(c + Vector2(-0.3, -0.5) * r, Vector2(0.6, 0.12) * r), dark)
		"scissors":
			ci.draw_line(c + Vector2(-0.5, -0.5) * r, c + Vector2(0.62, 0.52) * r, ink, w * 1.8)
			ci.draw_line(c + Vector2(-0.5, -0.5) * r, c + Vector2(0.62, 0.52) * r, Color(0.78, 0.8, 0.84), w)
			ci.draw_line(c + Vector2(-0.5, 0.5) * r, c + Vector2(0.62, -0.52) * r, ink, w * 1.8)
			ci.draw_line(c + Vector2(-0.5, 0.5) * r, c + Vector2(0.62, -0.52) * r, Color(0.78, 0.8, 0.84), w)
			ci.draw_arc(c + Vector2(-0.68, -0.6) * r, r * 0.2, 0, TAU, 16, ink, w * 1.5)
			ci.draw_arc(c + Vector2(-0.68, -0.6) * r, r * 0.2, 0, TAU, 16, col, w * 0.9)
			ci.draw_arc(c + Vector2(-0.68, 0.6) * r, r * 0.2, 0, TAU, 16, ink, w * 1.5)
			ci.draw_arc(c + Vector2(-0.68, 0.6) * r, r * 0.2, 0, TAU, 16, col, w * 0.9)
			_oc(ci, c, r * 0.07, ink, w * 0.5)
		"candle":
			_or(ci, Rect2(c + Vector2(-0.3, -0.08) * r, Vector2(0.6, 0.95) * r), col, w)
			_oe(ci, c + Vector2(0, -0.08) * r, r * 0.3, r * 0.09, Color(0.98, 0.96, 0.9), w * 0.6)
			ci.draw_line(c + Vector2(0, -0.1) * r, c + Vector2(0, -0.3) * r, ink, w * 0.6)
			_op(ci, [[0, -0.98], [0.19, -0.46], [0, -0.3], [-0.19, -0.46]], c, r, Color(0.97, 0.62, 0.18), w * 0.6)
			_op(ci, [[0, -0.72], [0.1, -0.44], [0, -0.34], [-0.1, -0.44]], c, r, Color(0.99, 0.86, 0.32), w * 0.4)
		"clock":
			_oc(ci, c, r * 0.92, col, w)
			_oc(ci, c, r * 0.72, Color(0.98, 0.97, 0.94), w * 0.6)
			for i in 4:
				var a := PI / 2.0 * float(i)
				ci.draw_line(c + Vector2(cos(a), sin(a)) * r * 0.56, c + Vector2(cos(a), sin(a)) * r * 0.68, ink, w * 0.7)
			ci.draw_line(c, c + Vector2(0.34, -0.18) * r, ink, w)
			ci.draw_line(c, c + Vector2(0, -0.52) * r, ink, w * 0.9)
			_oc(ci, c, r * 0.07, ink, w * 0.4)
		"fish":
			_op(ci, [[0.5, 0], [1.02, -0.44], [1.02, 0.44]], c, r, dark, w)
			_oe(ci, c, r * 0.78, r * 0.46, col, w)
			_op(ci, [[-0.05, -0.4], [0.28, -0.68], [0.36, -0.34]], c, r, dark, w * 0.7)
			_oc(ci, c + Vector2(-0.42, -0.1) * r, r * 0.11, Color.WHITE, w * 0.4)
			ci.draw_circle(c + Vector2(-0.42, -0.1) * r, r * 0.055, ink)
		"flower":
			for i in 5:
				var a := -PI / 2.0 + TAU * float(i) / 5.0
				_oc(ci, c + Vector2(cos(a), sin(a)) * r * 0.46, r * 0.4, col, w * 0.8)
			_oc(ci, c, r * 0.3, Color(0.98, 0.8, 0.25), w * 0.7)
			ci.draw_circle(c, r * 0.13, Color(0.85, 0.6, 0.15))
		"star":
			var star_pts := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + PI * float(i) / 5.0
				var rad := r * (0.95 if i % 2 == 0 else 0.45)
				star_pts.append(c + Vector2(cos(a), sin(a)) * rad)
			ci.draw_colored_polygon(star_pts, col)
			var star_line := PackedVector2Array(star_pts)
			star_line.append(star_pts[0])
			ci.draw_polyline(star_line, ink, w)
		"mushroom":
			_op(ci, [[-0.24, 0.08], [0.24, 0.08], [0.32, 0.82], [-0.32, 0.82]], c, r, Color(0.96, 0.91, 0.79), w)
			_hd(ci, c + Vector2(0, 0.12) * r, r * 0.88, col, w)
			ci.draw_circle(c + Vector2(-0.35, -0.3) * r, r * 0.12, Color(1, 1, 1, 0.9))
			ci.draw_circle(c + Vector2(0.28, -0.48) * r, r * 0.09, Color(1, 1, 1, 0.9))
			ci.draw_circle(c + Vector2(0.05, -0.14) * r, r * 0.07, Color(1, 1, 1, 0.9))
		"glasses":
			ci.draw_arc(c + Vector2(-0.48, 0) * r, r * 0.4, 0, TAU, 24, ink, w * 1.6)
			ci.draw_arc(c + Vector2(-0.48, 0) * r, r * 0.4, 0, TAU, 24, col, w)
			ci.draw_arc(c + Vector2(0.48, 0) * r, r * 0.4, 0, TAU, 24, ink, w * 1.6)
			ci.draw_arc(c + Vector2(0.48, 0) * r, r * 0.4, 0, TAU, 24, col, w)
			ci.draw_line(c + Vector2(-0.1, -0.06) * r, c + Vector2(0.1, -0.06) * r, col, w)
			ci.draw_line(c + Vector2(-0.86, -0.12) * r, c + Vector2(-1.05, -0.3) * r, col, w * 0.9)
			ci.draw_line(c + Vector2(0.86, -0.12) * r, c + Vector2(1.05, -0.3) * r, col, w * 0.9)
		"balloon":
			_oe(ci, c + Vector2(0, -0.18) * r, r * 0.62, r * 0.74, col, w)
			_oe(ci, c + Vector2(-0.2, -0.42) * r, r * 0.15, r * 0.25, Color(1, 1, 1, 0.4), w * 0.3)
			_op(ci, [[-0.09, 0.52], [0.09, 0.52], [0, 0.68]], c, r, dark, w * 0.6)
			var s := PackedVector2Array([c + Vector2(0, 0.68) * r, c + Vector2(0.12, 0.84) * r, c + Vector2(-0.04, 1.0) * r])
			ci.draw_polyline(s, ink, w * 0.6)
		"teapot":
			_oc(ci, c + Vector2(0, 0.12) * r, r * 0.62, col, w)
			_op(ci, [[-0.5, -0.12], [-0.98, -0.5], [-0.46, 0.28]], c, r, dark, w)
			ci.draw_arc(c + Vector2(0.62, 0.05) * r, r * 0.3, -PI / 2.0, PI / 2.0, 16, ink, w * 1.2)
			_or(ci, Rect2(c + Vector2(-0.25, -0.56) * r, Vector2(0.5, 0.12) * r), dark, w * 0.7)
			_oc(ci, c + Vector2(0, -0.64) * r, r * 0.09, dark, w * 0.6)
		"boot":
			_op(ci, [[-0.35, -0.85], [0.25, -0.85], [0.25, 0.32], [0.82, 0.4], [0.82, 0.78], [-0.35, 0.78]], c, r, col, w)
			ci.draw_rect(Rect2(c + Vector2(-0.35, -0.85) * r, Vector2(0.6, 0.2) * r), dark)
			ci.draw_line(c + Vector2(-0.35, 0.78) * r, c + Vector2(0.82, 0.78) * r, ink, w)
		"gift":
			_or(ci, Rect2(c + Vector2(-0.65, -0.22) * r, Vector2(1.3, 1.0) * r), col, w)
			_or(ci, Rect2(c + Vector2(-0.73, -0.5) * r, Vector2(1.46, 0.3) * r), dark, w)
			ci.draw_rect(Rect2(c + Vector2(-0.09, -0.5) * r, Vector2(0.18, 1.28) * r), Color(0.98, 0.82, 0.3))
			_oe(ci, c + Vector2(-0.2, -0.66) * r, r * 0.2, r * 0.11, Color(0.98, 0.82, 0.3), w * 0.6)
			_oe(ci, c + Vector2(0.2, -0.66) * r, r * 0.2, r * 0.11, Color(0.98, 0.82, 0.3), w * 0.6)
		"lamp":
			_op(ci, [[-0.58, -0.78], [0.58, -0.78], [0.36, -0.02], [-0.36, -0.02]], c, r, col, w)
			ci.draw_line(c + Vector2(0, -0.02) * r, c + Vector2(0, 0.68) * r, ink, w)
			ci.draw_line(c + Vector2(-0.42, 0.72) * r, c + Vector2(0.42, 0.72) * r, ink, w * 1.2)
			_oc(ci, c + Vector2(0, -0.2) * r, r * 0.1, Color(0.99, 0.87, 0.4), w * 0.5)
