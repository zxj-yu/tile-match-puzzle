extends CanvasLayer
# Roguelite 每层通关后的三选一增益界面。纯代码构建。
# 打开时传入待选增益，玩家点选后发出 chosen(id)。

signal chosen(id: String)

var _box: Panel
var _cards := []

func _ready():
	layer = 130          # 盖在结算面板之上
	visible = false
	_build_static()

func _build_static():
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_box = Panel.new()
	_box.position = Vector2(325, 175)
	_box.size = Vector2(500, 430)
	add_child(_box)

	var title = Label.new()
	title.text = "Choose a Buff"
	title.add_theme_font_size_override("font_size", 32)
	title.position = Vector2(30, 18)
	_box.add_child(title)

func open(buffs: Array):
	# 清掉上一次的卡片
	for c in _cards:
		if is_instance_valid(c):
			c.queue_free()
	_cards = []

	var y = 74
	for b in buffs:
		var btn = Button.new()
		btn.text = b["name"] + "\n" + b["desc"]
		btn.position = Vector2(30, y)
		btn.size = Vector2(440, 100)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ButtonStyler.style(btn, Color(0.55, 0.72, 0.95), 22)
		_box.add_child(btn)
		var id = str(b["id"])
		btn.pressed.connect(func(): _pick(id))
		_cards.append(btn)
		y += 112

	visible = true

func _pick(id: String):
	SoundManager.play("skill")
	visible = false
	emit_signal("chosen", id)
