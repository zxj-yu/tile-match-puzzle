extends Node

var sounds = {}
var bgm_player: AudioStreamPlayer = null
var sfx_players = []
const SFX_POOL_SIZE = 8
var next_player = 0

var sfx_enabled = true
var bgm_enabled = true

func _ready():
	_load_sound("click", "res://resources/sounds/click.ogg")
	_load_sound("match", "res://resources/sounds/match.ogg")
	_load_sound("combo", "res://resources/sounds/combo.ogg")
	_load_sound("skill", "res://resources/sounds/skill.ogg")
	_load_sound("win", "res://resources/sounds/win.ogg")
	_load_sound("lose", "res://resources/sounds/lose.ogg")
	_load_sound("button", "res://resources/sounds/button.ogg")

	for i in SFX_POOL_SIZE:
		var p = AudioStreamPlayer.new()
		add_child(p)
		sfx_players.append(p)

	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = -8.0
	add_child(bgm_player)
	_load_bgm("res://resources/sounds/bgm.ogg")

func _load_sound(name: String, path: String):
	if ResourceLoader.exists(path):
		sounds[name] = load(path)
	else:
		print("音效文件缺失（已跳过）: ", path)

func _load_bgm(path: String):
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		bgm_player.stream = stream
	else:
		print("BGM文件缺失（已跳过）: ", path)

func play(name: String):
	if not sfx_enabled:
		return
	if not sounds.has(name):
		return
	var p = sfx_players[next_player]
	next_player = (next_player + 1) % SFX_POOL_SIZE
	p.stream = sounds[name]
	p.play()

func play_bgm():
	if bgm_enabled and bgm_player.stream != null and not bgm_player.playing:
		bgm_player.play()

func stop_bgm():
	bgm_player.stop()

func toggle_sfx(on: bool):
	sfx_enabled = on

func toggle_bgm(on: bool):
	bgm_enabled = on
	if on:
		play_bgm()
	else:
		stop_bgm()
