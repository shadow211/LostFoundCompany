extends Node
## 全局状态：当前关卡、最佳星级（存 user://progress.json）

var selected_level: int = 0
var stars: Dictionary = {}  # level_index(int, as string in json) -> best stars

const SAVE_PATH := "user://progress.json"

# ---------- 音频：BGM 循环 + 音效池（素材在 res://audio/，代码合成） ----------
var _bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_streams: Dictionary = {}

func _ready() -> void:
	load_progress()
	_init_audio()

func _init_audio() -> void:
	for n in ["click", "pop", "found", "error", "hint", "win"]:
		var p := "res://audio/%s.wav" % n
		if ResourceLoader.exists(p):
			_sfx_streams[n] = load(p)
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.volume_db = -9.0
	if ResourceLoader.exists("res://audio/bgm.wav"):
		var s: AudioStreamWAV = load("res://audio/bgm.wav")
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = s.get_data().size() / 2
		_bgm_player.stream = s
	add_child(_bgm_player)
	for i in 4:
		var pl := AudioStreamPlayer.new()
		add_child(pl)
		_sfx_players.append(pl)
	if _bgm_player.stream != null:
		_bgm_player.play()

func play_sfx(sfx_name: String) -> void:
	if not _sfx_streams.has(sfx_name):
		return
	for pl in _sfx_players:
		if not pl.playing:
			pl.stream = _sfx_streams[sfx_name]
			pl.play()
			return
	_sfx_players[0].stream = _sfx_streams[sfx_name]
	_sfx_players[0].play()

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if data is Dictionary and data.has("stars"):
		stars = data["stars"]

func save_progress() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"stars": stars}))

func get_stars(level_index: int) -> int:
	return int(stars.get(str(level_index), 0))

func set_stars(level_index: int, value: int) -> void:
	if value > get_stars(level_index):
		stars[str(level_index)] = value
		save_progress()
