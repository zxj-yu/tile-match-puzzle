extends CanvasLayer
# 设置菜单：全屏遮罩 + 居中面板，含 音乐/音效 音量滑杆 与 静音开关。
# 整个界面在代码里构建，不依赖场景文件。

signal closed

var _bgm_slider: HSlider
var _sfx_slider: HSlider
var _bgm_value: Label
var _sfx_value: Label
var _mute_btn: CheckButton

func _ready():
	layer = 128          # 盖在所有 UI 之上
	visible = false
	_build()

func _build():
	# 半透明遮罩，拦截点击（铺满整个视口）
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# 面板
	var box = Panel.new()
	box.position = Vector2(335, 205)
	box.size = Vector2(480, 370)
	add_child(box)

	var title = Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 34)
	title.position = Vector2(30, 22)
	box.add_child(title)

	# 音乐音量
	_bgm_slider = _add_slider(box, "Music", 96, SoundManager.bgm_volume)
	_bgm_value = _add_value_label(box, 96, SoundManager.bgm_volume)
	# 音效音量
	_sfx_slider = _add_slider(box, "Sound", 160, SoundManager.sfx_volume)
	_sfx_value = _add_value_label(box, 160, SoundManager.sfx_volume)

	# 静音开关
	_mute_btn = CheckButton.new()
	_mute_btn.text = "  Mute all"
	_mute_btn.position = Vector2(30, 224)
	_mute_btn.add_theme_font_size_override("font_size", 22)
	_mute_btn.button_pressed = SoundManager.muted
	box.add_child(_mute_btn)

	# 关闭按钮
	var close = Button.new()
	close.text = "Close"
	close.position = Vector2(160, 296)
	close.size = Vector2(160, 52)
	ButtonStyler.style(close, Color(1.0, 0.62, 0.35), 22)
	box.add_child(close)

	# 信号连接
	_bgm_slider.value_changed.connect(_on_bgm_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_mute_btn.toggled.connect(_on_mute_toggled)
	close.pressed.connect(_on_close)

func _add_slider(box: Panel, label_text: String, y: int, init_linear: float) -> HSlider:
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.position = Vector2(30, y)
	box.add_child(lbl)

	var s = HSlider.new()
	s.min_value = 0
	s.max_value = 100
	s.step = 1
	s.value = round(init_linear * 100.0)
	s.position = Vector2(150, y + 6)
	s.size = Vector2(230, 24)
	box.add_child(s)
	return s

func _add_value_label(box: Panel, y: int, init_linear: float) -> Label:
	var v = Label.new()
	v.text = str(int(round(init_linear * 100.0)))
	v.add_theme_font_size_override("font_size", 22)
	v.position = Vector2(392, y)
	box.add_child(v)
	return v

func _on_bgm_changed(v: float):
	SoundManager.set_bgm_volume(v / 100.0)
	_bgm_value.text = str(int(v))

func _on_sfx_changed(v: float):
	SoundManager.set_sfx_volume(v / 100.0)
	_sfx_value.text = str(int(v))
	SoundManager.play("button")   # 试听音效音量

func _on_mute_toggled(on: bool):
	SoundManager.set_muted(on)

func _on_close():
	SoundManager.play("button")
	visible = false
	emit_signal("closed")

# 打开前把控件同步到当前设置
func open():
	_bgm_slider.set_value_no_signal(round(SoundManager.bgm_volume * 100.0))
	_sfx_slider.set_value_no_signal(round(SoundManager.sfx_volume * 100.0))
	_bgm_value.text = str(int(round(SoundManager.bgm_volume * 100.0)))
	_sfx_value.text = str(int(round(SoundManager.sfx_volume * 100.0)))
	_mute_btn.set_pressed_no_signal(SoundManager.muted)
	visible = true
