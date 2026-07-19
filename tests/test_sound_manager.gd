extends GutTest

# 测试前后快照并还原音量设置，避免污染真实存档
var _bgm
var _sfx
var _muted

func before_each():
	_bgm = SoundManager.bgm_volume
	_sfx = SoundManager.sfx_volume
	_muted = SoundManager.muted

func after_each():
	SoundManager.set_bgm_volume(_bgm)
	SoundManager.set_sfx_volume(_sfx)
	SoundManager.set_muted(_muted)

func test_set_sfx_volume_clamps_high():
	SoundManager.set_sfx_volume(1.5)
	assert_eq(SoundManager.sfx_volume, 1.0, "音量应被夹到上限 1.0")

func test_set_sfx_volume_clamps_low():
	SoundManager.set_sfx_volume(-0.3)
	assert_eq(SoundManager.sfx_volume, 0.0, "音量应被夹到下限 0.0")

func test_set_bgm_volume_persists_to_save():
	SoundManager.set_bgm_volume(0.35)
	assert_almost_eq(SoundManager.bgm_volume, 0.35, 0.001, "内存里的 BGM 音量应更新")
	assert_almost_eq(float(SaveManager.data["bgm_volume"]), 0.35, 0.001, "BGM 音量应写入存档")

func test_set_muted_updates_state_and_save():
	SoundManager.set_muted(true)
	assert_true(SoundManager.muted, "静音状态应为 true")
	assert_true(bool(SaveManager.data["muted"]), "静音状态应写入存档")
	SoundManager.set_muted(false)
	assert_false(SoundManager.muted, "取消静音后应为 false")

func test_muted_blocks_bgm_playback():
	# 静音时 play_bgm 不应让 BGM 播放
	SoundManager.set_muted(true)
	SoundManager.play_bgm()
	if SoundManager.bgm_player != null:
		assert_false(SoundManager.bgm_player.playing, "静音时 BGM 不应播放")
