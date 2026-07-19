extends CanvasLayer

signal level_chosen(index: int)
signal back_pressed

@onready var grid_container = $Panel/ScrollContainer/GridContainer
@onready var rank_label = $Panel/RankLabel

const BTN_SIZE = Vector2(110, 110)

func build(total_levels: int):
	# 清空旧按钮
	for c in grid_container.get_children():
		c.queue_free()

	# 顶部显示段位、总分、累计星数
	var rank = SaveManager.get_rank()
	var score = SaveManager.data["total_score"]
	rank_label.text = "Rank: %s    Total: %d    ★ %d" % [rank, score, SaveManager.total_stars()]

	var unlocked = SaveManager.data["unlocked_level"]

	for i in range(total_levels):
		var btn = Button.new()
		btn.custom_minimum_size = BTN_SIZE

		var stars = SaveManager.get_level_stars(i)

		if SaveManager.is_level_unlocked(i):
			# 已解锁：显示关号 + 星级
			var star_str = ""
			for s in range(3):
				star_str += "★" if s < stars else "☆"
			btn.text = str(i + 1) + "\n" + star_str
			btn.disabled = false
			var idx = i
			btn.pressed.connect(func(): emit_signal("level_chosen", idx))
			_style_button(btn, false)
		elif i <= unlocked:
			# 顺序到位，但累计星数不够：显示所需星数门槛
			btn.text = "%d\n🔒 %d★" % [i + 1, SaveManager.star_gate_for(i)]
			btn.disabled = true
			_style_button(btn, true)
		else:
			# 尚未按顺序解锁
			btn.text = str(i + 1) + "\n🔒"
			btn.disabled = true
			_style_button(btn, true)

		grid_container.add_child(btn)

# 给按钮上色：解锁的暖色，锁住的灰色
func _style_button(btn: Button, locked: bool):
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(12)
	if locked:
		style.bg_color = Color(0.7, 0.7, 0.7)
	else:
		style.bg_color = Color(1.0, 0.85, 0.4)  # 暖黄
	style.content_margin_left = 8
	style.content_margin_right = 8
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("disabled", style)
	btn.add_theme_color_override("font_color", Color(0.3, 0.25, 0.2))
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.45, 0.45))
	btn.add_theme_font_size_override("font_size", 22)

func show_menu():
	visible = true

func hide_menu():
	visible = false
