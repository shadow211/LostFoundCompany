extends SceneTree

## 无头冒烟测试 v3：图片场景 + 热点判定。
## 运行：godot --headless --path . -s tests/smoke_test.gd

var failures: Array[String] = []

func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: ", msg)
	else:
		failures.append(msg)
		printerr("  FAIL: ", msg)

func _init() -> void:
	call_deferred("run")

func empty_point(game) -> Vector2:
	for gx in range(70, 1560, 55):
		for gy in range(70, 1020, 55):
			var p := Vector2(gx, gy)
			var ok := true
			for t in game.targets:
				if p.distance_to(t["pos"]) < float(t["r"]) + 55.0:
					ok = false
					break
			if ok:
				for r in game.reactives:
					if p.distance_to(r["pos"]) < float(r["r"]) + 55.0:
						ok = false
						break
			if ok:
				for h in game.inhabitants:
					if p.distance_to(h["pos"]) < float(h["r"]) + 55.0:
						ok = false
						break
			if ok:
				return p
	return Vector2(5, 5)

func run() -> void:
	print("== smoke test v3 start ==")
	var state = root.get_node_or_null("GameState")
	check(state != null, "GameState autoload exists")
	check(state.has_method("play_sfx"), "audio: play_sfx exists")
	for n in ["bgm", "click", "pop", "found", "error", "hint", "win"]:
		check(ResourceLoader.exists("res://audio/%s.wav" % n), "audio file exists: %s" % n)
	state.play_sfx("click")

	var main_ps = load("res://scenes/Main.tscn")
	check(main_ps != null, "Main.tscn loads")
	var main_node = main_ps.instantiate()
	root.add_child(main_node)
	await process_frame
	await process_frame
	main_node.queue_free()
	await process_frame

	var game_ps = load("res://scenes/Game.tscn")
	check(game_ps != null, "Game.tscn loads")
	var level_count: int = Levels.DATA.size()
	for lv in range(level_count):
		state.selected_level = lv
		var game = game_ps.instantiate()
		root.add_child(game)
		await process_frame
		await process_frame
		check(game.dialogue_active, "level %d starts with dialogue" % lv)
		check(not game.playing, "level %d timer paused during dialogue" % lv)
		game.finish_dialogue()
		check(game.playing, "level %d playing after dialogue" % lv)
		# 悬停：目标与彩蛋都有动画，不收集、不计失误；已找到的目标不再悬停
		game._update_hover(game.targets[0]["pos"])
		check(not game.hovered.is_empty() and game.hovered["is_target"], "level %d hover target sets hovered" % lv)
		check(game.targets[0]["patch"].visible, "level %d hover target shows patch" % lv)
		check(game.found_count == 0, "level %d hover: no collect" % lv)
		check(game._hover_ring != null, "level %d hover shows ring" % lv)
		game._update_hover(empty_point(game))
		check(game.hovered.is_empty(), "level %d hover empty clears hovered" % lv)
		game._update_hover(game.reactives[0]["pos"])
		check(not game.hovered.is_empty() and not game.hovered["is_target"], "level %d hover reactive sets hovered" % lv)
		game._clear_hover()
		check(game.hovered.is_empty(), "level %d clear hover empties hovered" % lv)
		check(game.targets.size() == (game.level["targets"] as Array).size(), "level %d target count matches data" % lv)
		check(game.targets_left == game.targets.size(), "level %d targets_left initialized" % lv)
		# 热点互不重叠（圆心距 > 两半径之和的 0.8，避免判定歧义）
		var overlap := false
		for a in game.targets.size():
			for b in range(a + 1, game.targets.size()):
				var ta: Dictionary = game.targets[a]
				var tb: Dictionary = game.targets[b]
				if ta["pos"].distance_to(tb["pos"]) < (float(ta["r"]) + float(tb["r"])) * 0.8:
					overlap = true
		check(not overlap, "level %d hotspots do not overlap" % lv)
		# 热点都在世界范围内
		var inside := true
		for t in game.targets:
			var p: Vector2 = t["pos"]
			if p.x < 0 or p.y < 0 or p.x > 1600 or p.y > 1067:
				inside = false
		check(inside, "level %d hotspots inside world" % lv)
		# 彩蛋物体：数量、补丁精灵、点击触发反应且不计失误不计收集
		check(game.reactives.size() >= 3, "level %d has >=3 reactive objects" % lv)
		for r in game.reactives:
			check(String(r.get("who", "")).length() > 0 and String(r.get("act", "")) in ["yawn", "chirp", "sway", "glow", "pour", "flutter", "hop", "bob"], "level %d reactive %s has its own act %s" % [lv, r.get("who", "?"), r.get("act", "?")])
		# 住户：每关所有人/动物/花草都有待机呼吸，补丁从开场就显示，
		# 点中做本色动作、不计失误不计收集；住户之间、住户与目标不重叠
		check(game.inhabitants.size() >= 7, "level %d has >=7 inhabitants" % lv)
		for h in game.inhabitants:
			check(String(h.get("who", "")).length() > 0 and String(h.get("act", "")) in ["yawn", "chirp", "sway", "glow", "pour", "flutter", "hop", "bob"], "level %d inhabitant %s has its own act %s" % [lv, h.get("who", "?"), h.get("act", "?")])
			check(String(h.get("idle", "")) in ["breathe", "sway", "still"], "level %d inhabitant %s has idle %s" % [lv, h.get("who", "?"), h.get("idle", "?")])
			check(h["patch"] != null and h["patch"].visible, "level %d inhabitant %s patch visible from start" % [lv, h.get("who", "?")])
		# 静物住户（路灯/石灯）：待机不动，半秒后位置/缩放/旋转一点没变
		var stills: Array = []
		for h in game.inhabitants:
			if bool(h.get("still", false)):
				stills.append([h["patch"], h["patch"].position, h["patch"].scale, h["patch"].rotation, String(h.get("who", "?"))])
		if stills.size() > 0:
			await create_timer(0.5).timeout
			for s in stills:
				check(s[0].position == s[1] and s[0].scale == s[2] and s[0].rotation == s[3], "level %d still inhabitant %s stays put while idling" % [lv, s[4]])
		var inhab_overlap := false
		for h in game.inhabitants:
			for t in game.targets:
				if h["pos"].distance_to(t["pos"]) < float(h["r"]) + float(t["r"]):
					inhab_overlap = true
		check(not inhab_overlap, "level %d inhabitants do not overlap targets" % lv)
		if lv == 0 and game.inhabitants.size() > 0:
			var ih0: Dictionary = game.inhabitants[0]
			game._update_hover(ih0["pos"])
			check(not game.hovered.is_empty() and not game.hovered["is_target"] and game.hovered.get("is_inhabitant", false), "level %d hover inhabitant sets hovered" % lv)
			game._clear_hover()
			await create_timer(0.2).timeout
			check(ih0["patch"].visible, "level %d hover exit keeps inhabitant patch visible" % lv)
			var if0: int = game.found_count
			var ires: String = game.handle_click(ih0["pos"])
			check(ires == "inhabitant", "click inhabitant -> inhabitant")
			check(game.found_count == if0, "inhabitant click: no collect")
			await create_timer(0.6).timeout
			check(ih0["patch"].visible, "inhabitant patch stays visible after its act")
		if lv == 0 and game.reactives.size() > 0:
			var f0: int = game.found_count
			var rres: String = game.handle_click(game.reactives[0]["pos"])
			check(rres == "reactive", "click reactive -> reactive")
			check(game.found_count == f0, "reactive click: no collect")
			check(game.reactives[0]["patch"] != null, "reactive has patch sprite")
		# 静物彩蛋（浇水壶/灯笼/布料堆/石灯）：点中只亮一下，不位移、不缩放、不旋转
		for r in game.reactives:
			if bool(r.get("still", false)):
				var pp0: Vector2 = r["patch"].position
				var ss0: Vector2 = r["patch"].scale
				var rr0: float = r["patch"].rotation
				var srres: String = game.handle_click(r["pos"])
				check(srres == "reactive", "click still reactive %s -> reactive" % r.get("who", "?"))
				check(r["patch"].position == pp0 and r["patch"].scale == ss0 and r["patch"].rotation == rr0, "still reactive %s does not move on click" % r.get("who", "?"))
		# 相机
		game._zoom_at(Vector2(400, 400), 1.4)
		var wp: Vector2 = game.screen_to_world(Vector2(300, 300))
		check(wp.x > 0.0 and wp.y > 0.0, "level %d zoom + screen_to_world works" % lv)
		game._reset_cam()
		check(absf(game.zoom - game.ZOOM_MIN) < 0.001, "level %d reset view restores zoom" % lv)
		if lv == 0:
			var res: String = game.handle_click(game.targets[0]["pos"])
			check(res == "found" and game.found_count == 1, "click hotspot -> found")
			# 重复点已找到的热点不再计数
			res = game.handle_click(game.targets[0]["pos"])
			check(game.found_count == 1, "re-click found hotspot -> no double count")
			# 已找到的目标不再悬停
			game._update_hover(game.targets[0]["pos"])
			check(game.hovered.is_empty(), "hover found target -> no hover")
			# 点空地不计失误、不收集；HUD 里没有失误数
			var before: int = game.found_count
			res = game.handle_click(empty_point(game))
			check(res == "empty" and game.found_count == before, "click empty -> no mistake, no collect")
			check(not ("失误" in game.progress_label.text), "HUD shows no mistake count")
			# 提示扣次数
			var hb: int = game.hints_left
			game._on_hint()
			check(game.hints_left == hb - 1, "hint consumes one")
			# 找齐 -> 结算
			for i in game.targets.size():
				if not game.targets[i]["found"]:
					game.handle_click(game.targets[i]["pos"])
			# 亮绿圈 + 橙色气泡 0.9 秒后才留标记、结算
			await create_timer(1.2).timeout
			check(game.found_count == game.targets.size(), "all targets found")
			check(not game.playing, "game stops after win")
			check(game.win_panel.visible, "win panel visible")
			check(state.get_stars(0) >= 1, "stars saved for level 0")
		game.queue_free()
		await process_frame

	if failures.is_empty():
		print("== SMOKE TEST PASSED ==")
		quit(0)
	else:
		printerr("== SMOKE TEST FAILED: %d ==" % failures.size())
		quit(1)
