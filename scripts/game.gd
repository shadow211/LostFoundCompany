extends Control

## 关卡玩法 v3：场景为手绘风插图（整幅大图），目标物品以热点标定。
## 大场景可拖动平移 + 滚轮缩放；开场/结尾委托对话；点中热点收集
## （留下绿圈标记），点空计失误；提示时相机自动移向目标；评 1-3 星。

const VIEW_RECT := Rect2(16, 80, 968, 704)
const WORLD_SIZE := Vector2(1600, 1067)
const ZOOM_MIN := 0.66  # 按高度贴合画框，水平可平移
const ZOOM_MAX := 1.8

var level_index: int = 0
var level: Dictionary

var targets: Array = []  # {kind, color, pos: Vector2, r: float, found: bool}
var total_targets: int = 0
var targets_left: int = 0
var found_count: int = 0
var mistakes: int = 0
var hints_left: int = 0
var hints_used: int = 0
var elapsed: float = 0.0
var playing: bool = false

var cam := Vector2.ZERO
var zoom: float = ZOOM_MIN
var _press_pos := Vector2.ZERO
var _dragging := false

var dialogue_lines: Array = []
var dialogue_idx: int = -1
var dialogue_active: bool = false
var dialogue_panel: PanelContainer
var dialogue_name: Label
var dialogue_text: Label

var rows: Dictionary = {}  # target index -> {row, check}

var world: Node2D
var fx_root: Node2D
var scene_tex: Texture2D
var patch_root: Node2D
var reactives: Array = []  # {who, act, say, pos, r, patch}
var inhabitants: Array = []  # {who, act, say, idle, pos, r, patch, phase, speed, next_act}
var _idle_time := 0.0
const FOUND_FEEDBACK_DURATION := 0.9  # 找到反馈（绿圈+气泡）停留时间，之后才留常驻标记
# ---------- 悬停 ----------
var hovered: Dictionary = {}  # {} = 无悬停，否则 {"entry": Dictionary, "is_target": bool, "index": int}
var _hover_tween: Tween
var _hover_exit_tween: Tween
var _hover_ring: HoverRing
var _last_mouse_screen := Vector2.ZERO
var _hover_has_mouse := false
var title_label: Label
var progress_label: Label
var timer_label: Label
var hint_button: Button
var list_box: VBoxContainer
var win_panel: PanelContainer
var win_stars_label: Label
var win_detail: Label
var win_outro: Label
var next_button: Button
var miss_marker: Label

func _ready() -> void:
	_apply_font()
	level_index = clampi(GameState.selected_level, 0, Levels.DATA.size() - 1)
	level = Levels.DATA[level_index]
	_build_ui()
	_reset_cam()
	_start_level()
	_show_dialogue(level["intro"])

func _apply_font() -> void:
	if ResourceLoader.exists("res://fonts/NotoSansCJKsc-Regular.otf"):
		var font = load("res://fonts/NotoSansCJKsc-Regular.otf")
		var t := Theme.new()
		t.default_font = font
		t.default_font_size = 20
		theme = t

func _mk_label(text: String, size: int = 20, col: Color = Color(0.15, 0.13, 0.12)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _panel(col: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.border_color = Color(0.55, 0.42, 0.3)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

func _build_ui() -> void:
	var back := ColorRect.new()
	back.color = Color(0.97, 0.94, 0.87)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)

	var clip := Control.new()
	clip.position = VIEW_RECT.position
	clip.size = VIEW_RECT.size
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clip)
	world = Node2D.new()
	clip.add_child(world)

	# 场景大图
	var spr := Sprite2D.new()
	spr.texture = load(level["scene"])
	scene_tex = spr.texture
	spr.position = WORLD_SIZE * 0.5
	var ts: Vector2 = spr.texture.get_size()
	spr.scale = Vector2(WORLD_SIZE.x / ts.x, WORLD_SIZE.y / ts.y)
	world.add_child(spr)
	patch_root = Node2D.new()
	world.add_child(patch_root)
	fx_root = Node2D.new()
	world.add_child(fx_root)
	_apply_cam()

	var catcher := Control.new()
	catcher.position = VIEW_RECT.position
	catcher.size = VIEW_RECT.size
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.gui_input.connect(_on_scene_input)
	catcher.mouse_exited.connect(_clear_hover)
	add_child(catcher)

	var frame := ReferenceRect.new()
	frame.position = VIEW_RECT.position
	frame.size = VIEW_RECT.size
	frame.border_color = Color(0.5, 0.38, 0.26)
	frame.border_width = 3.0
	frame.editor_only = false
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 只画边框，绝不能吞场景的鼠标事件
	add_child(frame)

	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", _panel(Color(1, 0.99, 0.95)))
	top.position = Vector2(16, 12)
	top.size = Vector2(1248, 56)
	add_child(top)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 24)
	top.add_child(top_row)
	title_label = _mk_label("", 24)
	top_row.add_child(title_label)
	progress_label = _mk_label("", 20)
	top_row.add_child(progress_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	timer_label = _mk_label("00:00", 22)
	top_row.add_child(timer_label)
	hint_button = Button.new()
	hint_button.add_theme_font_size_override("font_size", 20)
	hint_button.pressed.connect(_on_hint)
	top_row.add_child(hint_button)
	var reset_view := Button.new()
	reset_view.text = "重置视图"
	reset_view.add_theme_font_size_override("font_size", 20)
	reset_view.pressed.connect(func() -> void:
		GameState.play_sfx("click")
		_reset_cam())
	top_row.add_child(reset_view)
	var menu_button := Button.new()
	menu_button.text = "返回菜单"
	menu_button.add_theme_font_size_override("font_size", 20)
	menu_button.pressed.connect(_on_menu)
	top_row.add_child(menu_button)

	var list_panel := PanelContainer.new()
	list_panel.add_theme_stylebox_override("panel", _panel(Color(1, 0.99, 0.95)))
	list_panel.position = Vector2(1000, 80)
	list_panel.size = Vector2(264, 704)
	add_child(list_panel)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 8)
	list_panel.add_child(lv)
	lv.add_child(_mk_label("要找的物品：", 20))
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 6)
	lv.add_child(list_box)
	lv.add_child(_mk_label("拖动平移 · 滚轮缩放\n物品就藏在画里，\n点空了计失误。", 15, Color(0.45, 0.42, 0.38)))

	miss_marker = _mk_label("✕", 34, Color(0.85, 0.2, 0.15))
	miss_marker.visible = false
	miss_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(miss_marker)

	_build_dialogue()
	_build_win_panel()

func _build_dialogue() -> void:
	dialogue_panel = PanelContainer.new()
	dialogue_panel.add_theme_stylebox_override("panel", _panel(Color(1, 0.98, 0.93)))
	dialogue_panel.position = Vector2(16, 800 - 168)
	dialogue_panel.size = Vector2(1248, 152)
	dialogue_panel.visible = false
	dialogue_panel.gui_input.connect(_on_dialogue_input)
	add_child(dialogue_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	dialogue_panel.add_child(v)
	dialogue_name = _mk_label("", 20, Color(0.6, 0.35, 0.15))
	v.add_child(dialogue_name)
	dialogue_text = _mk_label("", 22)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(dialogue_text)
	var hint := _mk_label("点击继续 ▸", 15, Color(0.55, 0.5, 0.44))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(hint)

func _build_win_panel() -> void:
	win_panel = PanelContainer.new()
	win_panel.add_theme_stylebox_override("panel", _panel(Color(1, 0.99, 0.95)))
	win_panel.custom_minimum_size = Vector2(460, 0)
	win_panel.position = Vector2(410, 210)
	win_panel.visible = false
	add_child(win_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	win_panel.add_child(v)
	var title := _mk_label("全部找到了！", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	win_outro = _mk_label("", 18, Color(0.4, 0.34, 0.26))
	win_outro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_outro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(win_outro)
	win_stars_label = _mk_label("", 40, Color(0.9, 0.65, 0.1))
	win_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(win_stars_label)
	win_detail = _mk_label("", 18)
	win_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(win_detail)
	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 12)
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(brow)
	next_button = Button.new()
	next_button.text = "下一关"
	next_button.add_theme_font_size_override("font_size", 20)
	next_button.pressed.connect(_on_next)
	brow.add_child(next_button)
	var replay := Button.new()
	replay.text = "重玩本关"
	replay.add_theme_font_size_override("font_size", 20)
	replay.pressed.connect(func() -> void:
		GameState.play_sfx("click")
		get_tree().reload_current_scene())
	brow.add_child(replay)
	var back_btn := Button.new()
	back_btn.text = "返回菜单"
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.pressed.connect(_on_menu)
	brow.add_child(back_btn)

# ---------- 对话 ----------
func _show_dialogue(lines: Array) -> void:
	_clear_hover()
	dialogue_lines = lines
	dialogue_idx = 0
	dialogue_active = true
	dialogue_panel.visible = true
	_refresh_dialogue()

func _refresh_dialogue() -> void:
	if dialogue_idx >= 0 and dialogue_idx < dialogue_lines.size():
		var line: Array = dialogue_lines[dialogue_idx]
		dialogue_name.text = line[0]
		dialogue_text.text = line[1]

func _on_dialogue_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GameState.play_sfx("click")
		dialogue_idx += 1
		if dialogue_idx >= dialogue_lines.size():
			finish_dialogue()
		else:
			_refresh_dialogue()

func finish_dialogue() -> void:
	dialogue_active = false
	dialogue_panel.visible = false
	if targets_left > 0:
		playing = true
		_update_hud()

# ---------- 相机 ----------
func _apply_cam() -> void:
	var view_size := VIEW_RECT.size / zoom
	cam.x = clampf(cam.x, 0.0, maxf(0.0, WORLD_SIZE.x - view_size.x))
	cam.y = clampf(cam.y, 0.0, maxf(0.0, WORLD_SIZE.y - view_size.y))
	world.position = -cam * zoom
	world.scale = Vector2.ONE * zoom

func _reset_cam() -> void:
	zoom = ZOOM_MIN
	var view_w := VIEW_RECT.size.x / zoom
	cam = Vector2(maxf(0.0, WORLD_SIZE.x - view_w) * 0.5, 0.0)
	_apply_cam()
	if _hover_has_mouse:
		_update_hover(screen_to_world(_last_mouse_screen))

func screen_to_world(p: Vector2) -> Vector2:
	return cam + (p - VIEW_RECT.position) / zoom

func _zoom_at(screen_pos: Vector2, factor: float) -> void:
	var before := screen_to_world(screen_pos)
	zoom = clampf(zoom * factor, ZOOM_MIN, ZOOM_MAX)
	cam = before - (screen_pos - VIEW_RECT.position) / zoom
	_apply_cam()
	_last_mouse_screen = screen_pos
	_update_hover(screen_to_world(screen_pos))

# ---------- 关卡数据 ----------
func _start_level() -> void:
	title_label.text = "第 %d 关 · %s" % [level_index + 1, level["name"]]
	hints_left = int(level["hints"])
	for i in (level["targets"] as Array).size():
		var t: Dictionary = level["targets"][i]
		var entry := {
			"kind": t["kind"], "color": t["color"],
			"pos": Vector2(float(t["x"]), float(t["y"])),
			"r": float(t["r"]), "found": false,
		}
		entry["patch"] = _make_patch(entry["pos"], maxf(float(t["r"]) * 1.4, 50.0))
		targets.append(entry)
		_add_list_row(i, entry)
	total_targets = targets.size()
	targets_left = total_targets
	for rd in level.get("reactives", []):
		var rentry := {
			"who": String(rd.get("who", "")), "act": String(rd.get("act", "sway")),
			"say": String(rd.get("say", "")),
			"pos": Vector2(float(rd["x"]), float(rd["y"])),
			"r": float(rd["r"]),
		}
		rentry["patch"] = _make_patch(rentry["pos"], maxf(float(rd["r"]) * 1.4, 48.0))
		reactives.append(rentry)
	# 住户：场景里所有人/动物/花草。补丁从开场就一直显示，待机呼吸不停；
	# 每隔几秒自己动一下，点中做本色动作、不计分、不收集。
	for id in level.get("inhabitants", []):
		var ientry := {
			"who": String(id.get("who", "")), "act": String(id.get("act", "bob")),
			"say": String(id.get("say", "")),
			"idle": String(id.get("idle", "breathe")),
			"pos": Vector2(float(id["x"]), float(id["y"])),
			"r": float(id["r"]),
		}
		var ipatch := _make_patch(ientry["pos"], maxf(float(id["r"]) * 1.4, 48.0))
		ipatch.visible = true
		ipatch.set_meta("inhabitant", true)
		ipatch.set_meta("base_scale", ipatch.scale)
		ipatch.set_meta("base_pos", ipatch.position)
		ientry["patch"] = ipatch
		ientry["phase"] = randf() * TAU
		ientry["speed"] = randf_range(2.2, 3.4)
		ientry["next_act"] = randf_range(4.0, 10.0)
		inhabitants.append(ientry)
	# 飘落的花瓣/叶子：每关 8 片，颜色按关卡走，循环飘落
	var petal_cols := [Color(1, 0.72, 0.82), Color(0.95, 0.85, 0.3), Color(1, 0.7, 0.85), Color(0.95, 0.6, 0.25)]
	var pc: Color = petal_cols[level_index]
	for k in 8:
		var petal := DriftPetal.new()
		petal.position = Vector2(randf_range(0.0, WORLD_SIZE.x), randf_range(0.0, WORLD_SIZE.y))
		petal.z_index = 60
		world.add_child(petal)
		petal.setup(pc, randf_range(5.0, 9.0), randf_range(16.0, 30.0))
	_update_hud()

# ---------- 交互动画：把场景图里物体所在的小块裁出来做补丁精灵，点击时播放动画 ----------
func _make_patch(pos: Vector2, half: float) -> Sprite2D:
	var img := scene_tex.get_image()
	var kx := float(img.get_width()) / WORLD_SIZE.x
	var ky := float(img.get_height()) / WORLD_SIZE.y
	var rect := Rect2i(int((pos.x - half) * kx), int((pos.y - half) * ky), int(half * 2.0 * kx), int(half * 2.0 * ky))
	rect = rect.intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	var sp := Sprite2D.new()
	sp.texture = ImageTexture.create_from_image(img.get_region(rect))
	sp.position = Vector2((float(rect.position.x) + rect.size.x * 0.5) / kx, (float(rect.position.y) + rect.size.y * 0.5) / ky)
	sp.scale = Vector2(1.0 / kx, 1.0 / ky)
	sp.visible = false
	sp.z_index = 100
	patch_root.add_child(sp)
	return sp

## 动作 tween 本体：只负责把动作播完，不负责播完后隐藏还是保留，
## 由 _animate_patch（播完隐藏）和 _play_inhabitant（播完保留）分别收尾。
func _tween_act(sp: Sprite2D, kind: String) -> Tween:
	var base_scale: Vector2 = sp.scale
	var base_pos: Vector2 = sp.position
	var tw := create_tween()
	match kind:
		"found":
			# 目标找到：只轻轻弹一下，真正的主角是亮绿圈 + 橙色气泡
			var tw2 := create_tween()
			tw2.tween_property(sp, "modulate", Color(1.5, 1.4, 1.1), 0.12)
			tw2.tween_property(sp, "modulate", Color.WHITE, 0.35)
			tw.tween_property(sp, "scale", base_scale * 1.12, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(sp, "scale", base_scale, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		"yawn":
			# 猫/狐狸打哈欠：慢慢伸长、顿一下、再缩回来
			tw.tween_property(sp, "scale", Vector2(base_scale.x * 0.94, base_scale.y * 1.18), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(sp, "rotation", 0.03, 0.35)
			tw.tween_interval(0.15)
			tw.tween_property(sp, "scale", base_scale, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(sp, "rotation", 0.0, 0.1)
		"chirp":
			# 小鸟叫：连跳两下
			tw.tween_property(sp, "position", base_pos + Vector2(0, -14), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(sp, "position", base_pos, 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tw.tween_property(sp, "position", base_pos + Vector2(0, -10), 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(sp, "position", base_pos, 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		"sway":
			# 花/草/向日葵摇动：左右摆，不转圈、不放大
			tw.tween_property(sp, "rotation", 0.12, 0.14)
			tw.tween_property(sp, "rotation", -0.10, 0.18)
			tw.tween_property(sp, "rotation", 0.06, 0.14)
			tw.tween_property(sp, "rotation", 0.0, 0.12)
		"glow":
			# 灯笼/石灯亮一下：提亮微胀，不转
			tw.tween_property(sp, "modulate", Color(1.7, 1.5, 1.1), 0.18)
			tw.parallel().tween_property(sp, "scale", base_scale * 1.06, 0.18)
			tw.tween_property(sp, "modulate", Color.WHITE, 0.35)
			tw.parallel().tween_property(sp, "scale", base_scale, 0.3)
		"pour":
			# 浇水壶：倾斜倒水，再回正
			tw.tween_property(sp, "rotation", -0.28, 0.18)
			tw.tween_interval(0.18)
			tw.tween_property(sp, "rotation", 0.0, 0.22)
		"flutter":
			# 布料堆：像被风吹一样抖两下
			tw.tween_property(sp, "scale", Vector2(base_scale.x * 1.10, base_scale.y * 0.94), 0.13)
			tw.tween_property(sp, "scale", Vector2(base_scale.x * 0.96, base_scale.y * 1.04), 0.14)
			tw.tween_property(sp, "scale", base_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		"hop":
			# 兔子：跳起落下
			tw.tween_property(sp, "position", base_pos + Vector2(0, -20), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(sp, "position", base_pos, 0.24).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		"bob":
			# 小人：原地轻轻蹦两下（个子小，幅度也小）
			tw.tween_property(sp, "position", base_pos + Vector2(0, -6), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(sp, "position", base_pos, 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tw.tween_property(sp, "position", base_pos + Vector2(0, -5), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(sp, "position", base_pos, 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	return tw

func _animate_patch(sp: Sprite2D, kind: String) -> void:
	if sp.get_meta("animating", false):
		return
	_detach_hover_for_patch(sp)
	if _hover_exit_tween and _hover_exit_tween.is_valid():
		_hover_exit_tween.kill()
	sp.set_meta("animating", true)
	sp.visible = true
	var base_scale: Vector2 = sp.scale
	var base_pos: Vector2 = sp.position
	var tw := _tween_act(sp, kind)
	tw.tween_callback(func() -> void:
		sp.rotation = 0.0
		sp.position = base_pos
		sp.scale = base_scale
		sp.modulate = Color.WHITE
		sp.visible = false
		sp.set_meta("animating", false))

# ---------- 悬停：鼠标移到可交互物体上就有动画 ----------
## 目标（未找到的）和彩蛋都算：只提亮 + 持续脉动的金圈 + 手形光标，
## 目标还会在右侧清单里高亮对应行。悬停不缩放、不摇晃、不做角色动作，
## 角色动作只在点中时才做——猫不会因为鼠标移上去就变大。
## 只在 playing 且无对话时生效；拖动、点中动画进行中不触发；不收集、不计失误。
func _find_hover(world_pos: Vector2) -> Dictionary:
	for i in targets.size():
		var t: Dictionary = targets[i]
		if not t["found"] and world_pos.distance_to(t["pos"]) <= float(t["r"]):
			return {"entry": t, "is_target": true, "index": i, "is_inhabitant": false}
	for i in reactives.size():
		var r: Dictionary = reactives[i]
		if world_pos.distance_to(r["pos"]) <= float(r["r"]):
			return {"entry": r, "is_target": false, "index": i, "is_inhabitant": false}
	for i in inhabitants.size():
		var h: Dictionary = inhabitants[i]
		if world_pos.distance_to(h["pos"]) <= float(h["r"]):
			return {"entry": h, "is_target": false, "index": i, "is_inhabitant": true}
	return {}

func _update_hover(world_pos: Vector2) -> void:
	if dialogue_active or not playing:
		_clear_hover()
		return
	_hover_has_mouse = true
	var next := _find_hover(world_pos)
	if next.is_empty():
		_clear_hover()
		return
	if not hovered.is_empty() and hovered["entry"] == next["entry"]:
		return
	var patch: Sprite2D = next["entry"]["patch"]
	if patch.get_meta("animating", false):
		_clear_hover()
		return
	_clear_hover()
	hovered = next
	_start_hover()

func _start_hover() -> void:
	if hovered.is_empty():
		return
	if _hover_exit_tween and _hover_exit_tween.is_valid():
		_hover_exit_tween.kill()
	var entry: Dictionary = hovered["entry"]
	var patch: Sprite2D = entry["patch"]
	patch.set_meta("hovering", true)
	patch.set_meta("hover_base_scale", patch.scale)
	patch.set_meta("hover_base_pos", patch.position)
	patch.visible = true
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(patch, "modulate", Color(1.22, 1.16, 1.02), 0.12)
	_hover_ring = HoverRing.new()
	_hover_ring.setup(float(entry["r"]) + 10.0)
	_hover_ring.position = entry["pos"]
	_hover_ring.z_index = 2900
	fx_root.add_child(_hover_ring)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	if hovered["is_target"] and rows.has(hovered["index"]):
		rows[hovered["index"]]["name"].add_theme_color_override("font_color", Color(0.85, 0.45, 0.05))

func _clear_hover() -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	if _hover_ring != null:
		_hover_ring.queue_free()
		_hover_ring = null
	if hovered.is_empty():
		return
	var entry: Dictionary = hovered["entry"]
	var patch: Sprite2D = entry["patch"]
	if hovered["is_target"] and rows.has(hovered["index"]):
		rows[hovered["index"]]["name"].add_theme_color_override("font_color", Color(0.15, 0.13, 0.12))
	hovered = {}
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if patch.get_meta("animating", false):
		patch.set_meta("hovering", false)
		return
	var base_scale: Vector2 = patch.get_meta("hover_base_scale", patch.scale)
	var base_pos: Vector2 = patch.get_meta("hover_base_pos", patch.position)
	patch.set_meta("hovering", false)
	_hover_exit_tween = create_tween()
	_hover_exit_tween.tween_property(patch, "modulate", Color.WHITE, 0.12)
	_hover_exit_tween.tween_callback(func() -> void:
		if not patch.get_meta("hovering", false) and not patch.get_meta("animating", false):
			if patch.get_meta("inhabitant", false):
				# 住户的补丁常驻显示（待机呼吸），移开只复原提亮，不隐藏
				patch.modulate = Color.WHITE
				return
			patch.visible = false
			patch.scale = base_scale
			patch.position = base_pos
			patch.rotation = 0.0
			patch.modulate = Color.WHITE)

## 点击动画接管同一块补丁时，先把悬停状态拆掉（不隐藏补丁、不跑复原 tween），
## 让点击动画完整跑完；光标和清单高亮同时复原。
func _detach_hover_for_patch(sp: Sprite2D) -> void:
	if hovered.is_empty():
		return
	var entry: Dictionary = hovered["entry"]
	if entry["patch"] != sp:
		return
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	if _hover_ring != null:
		_hover_ring.queue_free()
		_hover_ring = null
	if hovered["is_target"] and rows.has(hovered["index"]):
		rows[hovered["index"]]["name"].add_theme_color_override("font_color", Color(0.15, 0.13, 0.12))
	hovered = {}
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	sp.set_meta("hovering", false)

## 供截图验证：把悬停停在第 i 个目标上。
func debug_hover_target(i: int) -> void:
	if i >= 0 and i < targets.size() and not targets[i]["found"]:
		_update_hover(targets[i]["pos"])

func _add_list_row(idx: int, t: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var icon := ItemIcon.new()
	icon.setup(t["kind"], t["color"])
	row.add_child(icon)
	var name_label := _mk_label(ItemDraw.display_name(t["kind"], t["color"]), 19)
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name_label)
	var check := _mk_label("✓", 22, Color(0.3, 0.65, 0.3))
	check.visible = false
	check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(check)
	list_box.add_child(row)
	rows[idx] = {"row": row, "check": check, "name": name_label}

# ---------- 输入与玩法 ----------
func _on_scene_input(event: InputEvent) -> void:
	if dialogue_active or not playing:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at(event.position + VIEW_RECT.position, 1.12)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at(event.position + VIEW_RECT.position, 1.0 / 1.12)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_press_pos = event.position
				_dragging = false
			else:
				if not _dragging:
					var res := handle_click(screen_to_world(event.position + VIEW_RECT.position))
					if res == "empty":
						_show_miss(event.position + VIEW_RECT.position)
				_dragging = false
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_clear_hover()
			if _press_pos.distance_to(event.position) > 7.0:
				_dragging = true
			if _dragging:
				cam -= event.relative / zoom
				_apply_cam()
		else:
			_last_mouse_screen = event.position + VIEW_RECT.position
			_update_hover(screen_to_world(_last_mouse_screen))

## 返回 "found" / "reactive" / "inhabitant" / "empty"，供输入处理与测试共用。
## 判定顺序：目标 > 彩蛋 > 住户 > 空地。
func handle_click(pos: Vector2) -> String:
	if not playing:
		return "empty"
	for i in targets.size():
		var t: Dictionary = targets[i]
		if not t["found"] and pos.distance_to(t["pos"]) <= float(t["r"]):
			_found(i)
			return "found"
	for r in reactives:
		if pos.distance_to(r["pos"]) <= float(r["r"]):
			_play_reactive(r)
			return "reactive"
	for h in inhabitants:
		if pos.distance_to(h["pos"]) <= float(h["r"]):
			_play_inhabitant(h)
			return "inhabitant"
	mistakes += 1
	_spawn_ripple(pos, Color(0.95, 0.45, 0.4, 0.8), 34.0, 0.3)
	GameState.play_sfx("error")
	_update_hud()
	return "empty"

func _spawn_ripple(pos: Vector2, col: Color, max_r: float, dur: float) -> void:
	var rp := ClickRipple.new()
	rp.setup(col, max_r, dur)
	rp.position = pos
	rp.z_index = 3200
	fx_root.add_child(rp)

## 点中目标：立刻亮绿圈 + 橙色“找到了！”气泡（参考原作视频），
## 0.9 秒后才留绿圈✓标记。画笔画圈已不用，见 FoundRing/FoundBubble。
## 彩蛋和住户不在清单里，所以没有绿圈、没有“找到了！”、不计分——
## 这就是向日葵转了半天也不算找到的原因：它本来就不是要找的物品。
func _found(i: int) -> void:
	var t: Dictionary = targets[i]
	t["found"] = true
	found_count += 1
	targets_left -= 1
	GameState.play_sfx("found")
	_animate_patch(t["patch"], "found")
	var ring := FoundRing.new()
	ring.setup(float(t["r"]) + 14.0)
	ring.position = t["pos"]
	ring.z_index = 3400
	fx_root.add_child(ring)
	var bubble := FoundBubble.new()
	bubble.setup("找到了！")
	bubble.position = t["pos"] + Vector2(0, -float(t["r"]) - 34)
	bubble.z_index = 3600
	fx_root.add_child(bubble)
	_spawn_ripple(t["pos"], Color(0.4, 0.95, 0.35, 0.8), float(t["r"]) + 20.0, 0.4)
	_update_hud()
	var tw := create_tween()
	tw.tween_interval(FOUND_FEEDBACK_DURATION)
	tw.tween_callback(func() -> void: _finish_found(i))

func _finish_found(i: int) -> void:
	var t: Dictionary = targets[i]
	var sp := Sparkle.new()
	sp.position = t["pos"]
	sp.z_index = 3500
	fx_root.add_child(sp)
	var marker := FoundMarker.new()
	marker.position = t["pos"]
	marker.z_index = 3000
	fx_root.add_child(marker)
	if rows.has(i):
		rows[i]["check"].visible = true
		rows[i]["row"].modulate = Color(1, 1, 1, 0.45)
	_update_hud()
	if targets_left <= 0:
		_win()

func _show_miss(screen_pos: Vector2) -> void:
	miss_marker.position = screen_pos - Vector2(14, 22)
	miss_marker.visible = true
	var tw := create_tween()
	tw.tween_interval(0.4)
	tw.tween_callback(func() -> void: miss_marker.visible = false)

func _on_hint() -> void:
	if not playing or dialogue_active or hints_left <= 0:
		return
	var remaining: Array = []
	for i in targets.size():
		if not targets[i]["found"]:
			remaining.append(i)
	if remaining.is_empty():
		return
	hints_left -= 1
	hints_used += 1
	GameState.play_sfx("hint")
	var idx: int = remaining[randi() % remaining.size()]
	var pos: Vector2 = targets[idx]["pos"]
	cam = pos - VIEW_RECT.size * 0.5 / zoom
	_apply_cam()
	var ring := HintRing.new()
	ring.position = pos
	ring.z_index = 4000
	fx_root.add_child(ring)
	_update_hud()

## 供截图验证：把所有热点（目标+彩蛋+住户）圈出来。
func debug_show_hotspots() -> void:
	for t in targets:
		var ring := HintRing.new()
		ring.position = t["pos"]
		ring.z_index = 4000
		fx_root.add_child(ring)
	for r in reactives:
		var ring2 := HintRing.new()
		ring2.position = r["pos"]
		ring2.z_index = 4000
		fx_root.add_child(ring2)
	for h in inhabitants:
		var ring3 := HintRing.new()
		ring3.position = h["pos"]
		ring3.z_index = 4000
		fx_root.add_child(ring3)

## 彩蛋点中：只做它自己的动作（猫打哈欠、鸟叫、花摇……），不画圈、
## 不提示 "找到了！"、不计分、不收集。
func _play_reactive(entry: Dictionary) -> void:
	_animate_patch(entry["patch"], String(entry["act"]))
	var say := String(entry.get("say", ""))
	if not say.is_empty():
		var ft := FloatText.new()
		ft.setup(say, Color(0.5, 0.32, 0.12))
		ft.position = entry["pos"] + Vector2(0, -float(entry["r"]) - 18)
		ft.z_index = 3600
		fx_root.add_child(ft)
	_spawn_ripple(entry["pos"], Color(1, 1, 1, 0.85), float(entry["r"]) + 16.0, 0.35)
	GameState.play_sfx("pop")

## 供截图验证：触发第 i 个彩蛋物体的动画。
func debug_trigger_reactive(i: int) -> void:
	if i >= 0 and i < reactives.size():
		_play_reactive(reactives[i])

## 住户点中：和彩蛋一样，只做它自己的动作，不计分、不收集；
## 不同的是住户的补丁常驻显示，播完动作要留在原地继续待机呼吸，
## 不能像彩蛋那样播完隐藏。
func _play_inhabitant(entry: Dictionary) -> void:
	var patch: Sprite2D = entry["patch"]
	if patch.get_meta("animating", false):
		return
	_detach_hover_for_patch(patch)
	if _hover_exit_tween and _hover_exit_tween.is_valid():
		_hover_exit_tween.kill()
	patch.scale = patch.get_meta("base_scale", patch.scale)
	patch.rotation = 0.0
	patch.position = patch.get_meta("base_pos", patch.position)
	patch.modulate = Color.WHITE
	patch.visible = true
	patch.set_meta("animating", true)
	var base_scale: Vector2 = patch.get_meta("base_scale", patch.scale)
	var base_pos: Vector2 = patch.get_meta("base_pos", patch.position)
	var tw := _tween_act(patch, String(entry["act"]))
	tw.tween_callback(func() -> void:
		patch.rotation = 0.0
		patch.position = base_pos
		patch.scale = base_scale
		patch.modulate = Color.WHITE
		patch.visible = true
		patch.set_meta("animating", false))
	var say := String(entry.get("say", ""))
	if not say.is_empty():
		var ft := FloatText.new()
		ft.setup(say, Color(0.5, 0.32, 0.12))
		ft.position = entry["pos"] + Vector2(0, -float(entry["r"]) - 18)
		ft.z_index = 3600
		fx_root.add_child(ft)
	_spawn_ripple(entry["pos"], Color(1, 1, 1, 0.85), float(entry["r"]) + 16.0, 0.35)
	GameState.play_sfx("pop")

## 供截图验证：触发第 i 个住户的动画。
func debug_trigger_inhabitant(i: int) -> void:
	if i >= 0 and i < inhabitants.size():
		_play_inhabitant(inhabitants[i])

func _process(delta: float) -> void:
	if playing and not dialogue_active:
		elapsed += delta
		timer_label.text = _fmt_time(elapsed)
	# 住户待机：每帧按正弦呼吸/轻摆；对话和结算时也动，场景一直是活的。
	# 点中动画或悬停时不动手，等动作播完再接上。
	_idle_time += delta
	for h in inhabitants:
		var patch: Sprite2D = h["patch"]
		if patch.get_meta("animating", false) or patch.get_meta("hovering", false):
			continue
		var base_scale: Vector2 = patch.get_meta("base_scale", patch.scale)
		var ph: float = float(h["phase"])
		var sp: float = float(h["speed"])
		if String(h["idle"]) == "sway":
			patch.rotation = 0.03 * sin(_idle_time * sp * 0.6 + ph)
		else:
			var s := 1.0 + 0.035 * sin(_idle_time * sp + ph)
			patch.scale = Vector2(base_scale.x, base_scale.y * s)
		if playing and not dialogue_active:
			h["next_act"] = float(h["next_act"]) - delta
			if float(h["next_act"]) <= 0.0:
				h["next_act"] = randf_range(7.0, 14.0)
				_play_inhabitant(h)

func _fmt_time(sec: float) -> String:
	var s := int(sec)
	return "%02d:%02d" % [s / 60, s % 60]

func _update_hud() -> void:
	progress_label.text = "已找到 %d / %d · 失误 %d" % [found_count, total_targets, mistakes]
	hint_button.text = "提示（剩 %d）" % hints_left
	hint_button.disabled = hints_left <= 0 or not playing or dialogue_active

func _win() -> void:
	_clear_hover()
	playing = false
	GameState.play_sfx("win")
	var star_count := 3
	if hints_used > 0:
		star_count -= 1
	if mistakes > 5:
		star_count -= 1
	if elapsed > float(level["par_time"]) * 1.5:
		star_count -= 1
	star_count = maxi(star_count, 1)
	GameState.set_stars(level_index, star_count)
	win_stars_label.text = "★".repeat(star_count) + "☆".repeat(3 - star_count)
	win_detail.text = "用时 %s · 失误 %d 次 · 提示 %d 次" % [_fmt_time(elapsed), mistakes, hints_used]
	var outro_text := ""
	for line in level["outro"]:
		outro_text += line[0] + "：" + line[1] + "\n"
	win_outro.text = outro_text.strip_edges()
	next_button.visible = level_index < Levels.DATA.size() - 1
	win_panel.visible = true
	_update_hud()

func _on_next() -> void:
	GameState.play_sfx("click")
	GameState.selected_level = level_index + 1
	get_tree().reload_current_scene()

func _on_menu() -> void:
	_clear_hover()
	GameState.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
