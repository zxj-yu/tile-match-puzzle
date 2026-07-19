extends Node

var sounds = {}
var bgm_player: AudioStreamPlayer = null
var sfx_players = []
const SFX_POOL_SIZE = 8
var next_player = 0

# ===== 音量设置（线性 0~1）+ 总静音 =====
var sfx_volume := 1.0
var bgm_volume := 0.6
var muted := false

func _ready():
	# 1. 加载音效
	_load_sound("click", "res://resources/sounds/click.ogg")
	_load_sound("match", "res://resources/sounds/match.ogg")
	_load_sound("combo", "res://resources/sounds/combo.ogg")
	_load_sound("skill", "res://resources/sounds/skill.ogg")
	_load_sound("win", "res://resources/sounds/win.ogg")
	_load_sound("lose", "res://resources/sounds/lose.ogg")
	_load_sound("button", "res://resources/sounds/button.ogg")

	# 2. 创建音效播放器池
	for i in SFX_POOL_SIZE:
		var p = AudioStreamPlayer.new()
		add_child(p)
		sfx_players.append(p)

	# 3. 先创建 BGM 播放器，再加载 BGM（顺序不能反！）
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	_load_bgm("res://resources/sounds/bgm.mp3")

	# 4. 从存档载入音量设置并应用（SaveManager 在自动加载顺序里排在前面）
	_load_settings()
	_apply_bgm_volume()

func _load_settings():
	sfx_volume = clamp(float(SaveManager.data.get("sfx_volume", 1.0)), 0.0, 1.0)
	bgm_volume = clamp(float(SaveManager.data.get("bgm_volume", 0.6)), 0.0, 1.0)
	muted = bool(SaveManager.data.get("muted", false))

func _load_sound(name: String, path: String):
	if ResourceLoader.exists(path):
		sounds[name] = load(path)
	else:
		print("音效文件缺失（已跳过）: ", path)

func _load_bgm(path: String):
	if bgm_player == null:
		return
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		elif stream is AudioStreamMP3:
			stream.loop = true
		bgm_player.stream = stream
	else:
		print("BGM文件缺失（已跳过）: ", path)

# 线性音量 → 分贝；音量为 0 时给一个极小值避免 -inf
func _vol_to_db(v: float) -> float:
	return linear_to_db(max(v, 0.0001))

func play(name: String):
	if muted or sfx_volume <= 0.0:
		return
	if not sounds.has(name):
		return
	var p = sfx_players[next_player]
	next_player = (next_player + 1) % SFX_POOL_SIZE
	p.stream = sounds[name]
	p.volume_db = _vol_to_db(sfx_volume)
	p.play()

func play_bgm():
	if muted or bgm_volume <= 0.0:
		return
	if bgm_player != null and bgm_player.stream != null and not bgm_player.playing:
		bgm_player.play()

func stop_bgm():
	if bgm_player != null:
		bgm_player.stop()

# 根据当前音量/静音，实时调整 BGM 播放与音量
func _apply_bgm_volume():
	if bgm_player == null:
		return
	bgm_player.volume_db = _vol_to_db(bgm_volume)
	if muted or bgm_volume <= 0.0:
		if bgm_player.playing:
			bgm_player.stop()
	else:
		if bgm_player.stream != null and not bgm_player.playing:
			bgm_player.play()

# ===== 设置接口（供设置菜单调用，改动即存档）=====
func set_sfx_volume(v: float):
	sfx_volume = clamp(v, 0.0, 1.0)
	SaveManager.data["sfx_volume"] = sfx_volume
	SaveManager.save_game()

func set_bgm_volume(v: float):
	bgm_volume = clamp(v, 0.0, 1.0)
	SaveManager.data["bgm_volume"] = bgm_volume
	_apply_bgm_volume()
	SaveManager.save_game()

func set_muted(m: bool):
	muted = m
	SaveManager.data["muted"] = muted
	_apply_bgm_volume()
	SaveManager.save_game()
