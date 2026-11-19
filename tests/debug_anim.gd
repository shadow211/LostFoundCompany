extends SceneTree

## 调试：验证目标点击的补丁动画与找到标记是否真的渲染。
## 运行：xvfb-run godot --path . -s tests/debug_anim.gd

func _init() -> void:
	call_deferred("run")

func snap(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png("res://tests/shots/%s.png" % name)
	print("saved ", name)

func wait_sec(sec: float) -> void:
	await create_timer(sec).timeout

func run() -> void:
	var state = root.get_node("GameState")
	state.selected_level = 0
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.finish_dialogue()
	var patch = game.targets[0]["patch"]
	print("patch tex null? ", patch.texture == null, " size: ", patch.texture.get_size() if patch.texture else Vector2i.ZERO)
	print("patch pos: ", patch.position, " scale: ", patch.scale, " visible: ", patch.visible, " z: ", patch.z_index)
	var res: String = game.handle_click(game.targets[0]["pos"])
	print("click result: ", res, " found_count: ", game.found_count)
	print("patch visible right after click: ", patch.visible)
	await wait_sec(0.16)
	print("patch scale mid-anim: ", patch.scale, " (base 0.833, peak ~0.93 for found)")
	await snap("debug_found_mid")
	await wait_sec(0.8)
	print("patch visible after anim: ", patch.visible)
	await snap("debug_found_done")
	var rp = game.reactives[0]["patch"]
	game.debug_trigger_reactive(0)
	await wait_sec(0.07)
	print("reactive patch visible mid-anim: ", rp.visible, " pos: ", rp.position)
	await snap("debug_reactive_mid")
	print("== debug done ==")
	quit(0)
