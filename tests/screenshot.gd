extends SceneTree

## 截图验证 v3：菜单 + 对话开场 + 3 关全景 + 热点圈对齐图 + 放大视图。
## 运行：xvfb-run godot --path . -s tests/screenshot.gd

func _init() -> void:
	call_deferred("run")

func snap(name: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png("res://tests/shots/%s.png" % name)
	print("saved ", name, " ", img.get_size())

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/shots"))
	var state = root.get_node("GameState")
	var main_node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main_node)
	await snap("menu")
	main_node.queue_free()
	await process_frame
	var game_ps = load("res://scenes/Game.tscn")
	for lv in range(Levels.DATA.size()):
		state.selected_level = lv
		var game = game_ps.instantiate()
		root.add_child(game)
		await process_frame
		await process_frame
		if lv == 0:
			await snap("level1_dialogue")
		game.finish_dialogue()
		await snap("level%d" % (lv + 1))
		if lv == 0:
			game.debug_hover_target(0)
			await create_timer(0.25).timeout
			await snap("level1_hover")
			game._clear_hover()
			await create_timer(0.2).timeout
			game.handle_click(game.targets[0]["pos"])
			await create_timer(0.25).timeout
			await snap("level1_found_circle")
			await create_timer(0.6).timeout
			await snap("level1_found_done")
			game.debug_trigger_reactive(0)
			await create_timer(0.35).timeout
			await snap("level1_cat_yawn")
		game.debug_show_hotspots()
		await snap("level%d_hotspots" % (lv + 1))
		game.debug_trigger_reactive(0)
		await snap("level%d_anim" % (lv + 1))
		if lv == 0:
			game._zoom_at(Vector2(500, 440), 1.7)
			await snap("level1_zoom")
		game.queue_free()
		await process_frame
	print("== screenshots done ==")
	quit(0)
