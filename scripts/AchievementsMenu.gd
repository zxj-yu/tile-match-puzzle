extends CanvasLayer
# 成就查看界面：全屏遮罩 + 居中面板，滚动列出所有成就及解锁状态。
# 纯代码构建，打开时刷新（解锁状态可能已变化）。

signal closed

var _list_box: VBoxContainer
var _header: Label

func _ready():
	layer = 128
	visible = false
	_build()

func _build():
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var box = Panel.new()
	box.position = Vector2(300, 110)
	box.size = Vector2(550, 560)
	add_child(box)

	var title = Label.new()
	title.text = "Achievements"
	title.add_theme_font_size_override("font_size", 34)
	title.position = Vector2(28, 20)
	box.add_child(title)

	_header = Label.new()
	_header.add_theme_font_size_override("font_size", 20)
	_header.position = Vector2(30, 66)
	box.add_child(_header)

	# 滚动区域
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(24, 104)
	scroll.size = Vector2(502, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	_list_box = VBoxContainer.new()
	_list_box.custom_minimum_size = Vector2(490, 0)
	_list_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_list_box)

	var close = Button.new()
	close.text = "Close"
	close.position = Vector2(195, 496)
	close.size = Vector2(160, 52)
	ButtonStyler.style(close, Color(1.0, 0.62, 0.35), 22)
	box.add_child(close)
	close.pressed.connect(_on_close)

func _refresh():
	# 清空旧行
	for c in _list_box.get_children():
		c.queue_free()

	var all = AchievementManager.get_all()
	_header.text = "Unlocked  %d / %d" % [AchievementManager.unlocked_count(), all.size()]

	for a in all:
		var unlocked = AchievementManager.is_unlocked(a["id"])
		var row = Label.new()
		row.add_theme_font_size_override("font_size", 21)
		var icon = "🏆 " if unlocked else "🔒 "
		row.text = icon + a["name"] + " — " + a["desc"]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.custom_minimum_size = Vector2(480, 0)
		# 已解锁亮色，未解锁灰暗
		row.modulate = Color(1, 1, 1) if unlocked else Color(0.55, 0.55, 0.58)
		_list_box.add_child(row)

func _on_close():
	SoundManager.play("button")
	visible = false
	emit_signal("closed")

func open():
	_refresh()
	visible = true
