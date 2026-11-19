extends Control

## 主菜单：标题 + 关卡选择（显示最佳星级）+ 玩法说明。

func _ready() -> void:
	_apply_font()
	_build()

func _apply_font() -> void:
	if ResourceLoader.exists("res://fonts/NotoSansCJKsc-Regular.otf"):
		var font = load("res://fonts/NotoSansCJKsc-Regular.otf")
		var t := Theme.new()
		t.default_font = font
		t.default_font_size = 20
		theme = t

func _mk_label(text: String, size: int, col: Color = Color(0.15, 0.13, 0.12), center: bool = true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _build() -> void:
	var back := ColorRect.new()
	back.color = Color(0.96, 0.93, 0.86)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	center.add_child(v)

	v.add_child(_mk_label("🔍", 54))
	v.add_child(_mk_label("寻物小铺", 56, Color(0.35, 0.22, 0.1)))
	v.add_child(_mk_label("在热闹的场景里，按清单找出藏起来的物品！", 20, Color(0.45, 0.4, 0.33)))
	v.add_child(_mk_label("点中目标即可收集；点到别的东西它会晃一晃，点空地才计失误。", 17, Color(0.5, 0.46, 0.4)))
	v.add_child(_mk_label("操作：拖动平移场景 · 滚轮缩放 · 卡住时用提示", 16, Color(0.5, 0.46, 0.4)))

	var rows := HBoxContainer.new()
	rows.add_theme_constant_override("separation", 14)
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(rows)
	for i in Levels.DATA.size():
		var lv: Dictionary = Levels.DATA[i]
		var best := GameState.get_stars(i)
		var star_text := ""
		if best > 0:
			star_text = "\n最佳：" + "★".repeat(best) + "☆".repeat(3 - best)
		var b := Button.new()
		b.custom_minimum_size = Vector2(230, 110)
		b.add_theme_font_size_override("font_size", 20)
		b.text = "第 %d 关\n%s\n找 %d 个物品%s" % [i + 1, lv["name"], (lv["targets"] as Array).size(), star_text]
		var idx := i
		b.pressed.connect(func() -> void:
			GameState.play_sfx("click")
			GameState.selected_level = idx
			get_tree().change_scene_to_file("res://scenes/Game.tscn"))
		rows.add_child(b)

	v.add_child(_mk_label("灵感来自隐藏物品类游戏 · 代码与图形均为原创的练习作品", 14, Color(0.6, 0.56, 0.5)))
