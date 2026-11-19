extends SceneTree

## 端到端输入测试：用真实输入事件（Viewport.push_input）验证
## 对话点击推进、悬停动画、滚轮缩放、拖动平移、点击收集、点空计失误。
## 必须在带窗口的环境跑：xvfb-run godot --path . -s tests/input_test.gd

var failures: Array[String] = []

func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: ", msg)
	else:
		failures.append(msg)
		printerr("  FAIL: ", msg)

func _init() -> void:
	call_deferred("run")

func push_btn(pos: Vector2, button: int, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = pressed
	ev.position = pos
	root.push_input(ev)
	await process_frame
	await process_frame

func push_motion(pos: Vector2, rel: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = pos
	ev.relative = rel
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(ev)
	await process_frame
	await process_frame

## 真实悬停：不按任何键的鼠标移动（button_mask = 0）。
func push_hover(pos: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = pos
	ev.relative = Vector2.ZERO
	ev.button_mask = 0
	root.push_input(ev)
	await process_frame
	await process_frame
	await process_frame

func wait_sec(sec: float) -> void:
	await create_timer(sec).timeout

func empty_screen_point(game) -> Vector2:
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
				return game.VIEW_RECT.position + (p - game.cam) * game.zoom
	return Vector2(60, 750)

func run() -> void:
	print("== input test start ==")
	var state = root.get_node("GameState")
	state.selected_level = 0
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	# 1) 点对话框推进对话
	await push_btn(Vector2(640, 700), MOUSE_BUTTON_LEFT, true)
	await push_btn(Vector2(640, 700), MOUSE_BUTTON_LEFT, false)
	check(game.dialogue_idx == 1, "click dialogue panel advances dialogue")
	await push_btn(Vector2(640, 700), MOUSE_BUTTON_LEFT, true)
	await push_btn(Vector2(640, 700), MOUSE_BUTTON_LEFT, false)
	check(not game.dialogue_active and game.playing, "dialogue finished via clicks, game playing")

	# 2) 真实悬停目标 -> 有动画、不收集、不计失误
	var t0: Vector2 = game.targets[0]["pos"]
	var s0: Vector2 = game.VIEW_RECT.position + (t0 - game.cam) * game.zoom
	var base_scale: Vector2 = game.targets[0]["patch"].scale
	await push_hover(s0)
	check(not game.hovered.is_empty() and game.hovered["is_target"], "hover target sets hovered")
	check(game.targets[0]["patch"].visible, "hover target shows patch")
	check(game.found_count == 0 and game.mistakes == 0, "hover does not collect or count a mistake")
	check(game._hover_ring != null, "hover target shows pulsing ring")
	await wait_sec(0.25)
	check(absf(game.targets[0]["patch"].scale.x - base_scale.x) < 0.02, "hover does NOT scale the object (%.3f, stays %.3f)" % [base_scale.x, game.targets[0]["patch"].scale.x])
	check(game.targets[0]["patch"].modulate.r > 1.05, "hover brightens the patch")
	# 移到空地 -> 悬停清除，补丁复原隐藏
	var ep0 := empty_screen_point(game)
	await push_hover(ep0)
	check(game.hovered.is_empty(), "hover empty point clears hovered")
	await wait_sec(0.3)
	check(not game.targets[0]["patch"].visible, "hover exit hides patch again")
	# 悬停彩蛋 -> 有动画、不收集、不计失误
	var r0: Vector2 = game.reactives[0]["pos"]
	var sr0: Vector2 = game.VIEW_RECT.position + (r0 - game.cam) * game.zoom
	await push_hover(sr0)
	check(not game.hovered.is_empty() and not game.hovered["is_target"], "hover reactive sets hovered")
	check(game.reactives[0]["patch"].visible, "hover reactive shows patch")
	check(game.found_count == 0 and game.mistakes == 0, "hover reactive: no collect, no mistake")
	# 拖动时悬停清除（按住左键移动是平移，不是悬停）
	await push_btn(sr0, MOUSE_BUTTON_LEFT, true)
	await push_motion(Vector2(320, 400), Vector2(-80, 0))
	check(game.hovered.is_empty(), "drag motion clears hover")
	await push_btn(Vector2(320, 400), MOUSE_BUTTON_LEFT, false)
	game._reset_cam()

	# 3) 滚轮缩放
	var z0: float = game.zoom
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.position = Vector2(400, 400)
	root.push_input(wheel)
	await process_frame
	await process_frame
	check(game.zoom > z0, "wheel up zooms in (%.3f -> %.3f)" % [z0, game.zoom])
	game._reset_cam()

	# 4) 拖动平移
	var cam0: Vector2 = game.cam
	await push_btn(Vector2(400, 400), MOUSE_BUTTON_LEFT, true)
	await push_motion(Vector2(320, 400), Vector2(-80, 0))
	await push_motion(Vector2(260, 400), Vector2(-60, 0))
	await push_btn(Vector2(260, 400), MOUSE_BUTTON_LEFT, false)
	check(game.cam.x > cam0.x + 10.0, "drag pans camera (x %.1f -> %.1f)" % [cam0.x, game.cam.x])
	game._reset_cam()

	# 5) 真实点击目标 -> 画笔画圈 + 找到，0.55 秒后留绿圈✓
	var tpos: Vector2 = game.targets[0]["pos"]
	var spos: Vector2 = game.VIEW_RECT.position + (tpos - game.cam) * game.zoom
	await push_btn(spos, MOUSE_BUTTON_LEFT, true)
	await push_btn(spos, MOUSE_BUTTON_LEFT, false)
	check(game.found_count == 1, "real click on target collects it")
	await wait_sec(0.7)
	check(game.rows[0]["check"].visible, "found target shows check after pen circle")
	# 5b) 真实点击彩蛋猫 -> 打哈欠本色动作，不计分
	var m_before: int = game.mistakes
	var f_before: int = game.found_count
	var cat_pos: Vector2 = game.reactives[0]["pos"]
	var cat_spos: Vector2 = game.VIEW_RECT.position + (cat_pos - game.cam) * game.zoom
	await push_btn(cat_spos, MOUSE_BUTTON_LEFT, true)
	await push_btn(cat_spos, MOUSE_BUTTON_LEFT, false)
	check(game.found_count == f_before and game.mistakes == m_before, "click cat reactive: no collect, no mistake")
	check(game.reactives[0]["who"] == "灰猫" and game.reactives[0]["act"] == "yawn", "cat reactive is a yawning cat, not a generic scale")

	# 6) 真实点击空地 -> 失误+1
	var m0: int = game.mistakes
	var ep := empty_screen_point(game)
	await push_btn(ep, MOUSE_BUTTON_LEFT, true)
	await push_btn(ep, MOUSE_BUTTON_LEFT, false)
	check(game.mistakes == m0 + 1, "real click on empty counts a mistake")

	if failures.is_empty():
		print("== INPUT TEST PASSED ==")
		quit(0)
	else:
		printerr("== INPUT TEST FAILED: %d ==" % failures.size())
		quit(1)
