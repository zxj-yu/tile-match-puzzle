class_name ButtonStyler
extends Node

# 给按钮应用"充气糖果"风格
# base_color: 主体色。会自动生成高光、厚度边、按下态
static func style(btn: Button, base_color: Color, font_size: int = 20):
	# 正常态：亮色主体 + 底部厚边（充气感的关键）
	var normal = StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.set_corner_radius_all(16)
	normal.border_width_bottom = 6
	normal.border_color = base_color.darkened(0.35)   # 厚度边=主体加深
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	normal.shadow_size = 4
	normal.shadow_color = Color(0, 0, 0, 0.15)
	normal.shadow_offset = Vector2(0, 3)

	# 悬停态：变亮一点
	var hover = normal.duplicate()
	hover.bg_color = base_color.lightened(0.12)

	# 按下态：下沉（厚边消失+往下移的视觉）
	var pressed = normal.duplicate()
	pressed.bg_color = base_color.darkened(0.1)
	pressed.border_width_bottom = 2
	pressed.content_margin_top = 12
	pressed.content_margin_bottom = 4
	pressed.shadow_size = 0

	# 禁用态：灰
	var disabled = normal.duplicate()
	disabled.bg_color = Color(0.75, 0.73, 0.7)
	disabled.border_color = Color(0.6, 0.58, 0.55)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)

	# 文字：白色+深色描边（糖果字）
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0.9))
	btn.add_theme_color_override("font_disabled_color", Color(0.9, 0.9, 0.9))
	btn.add_theme_color_override("font_outline_color", base_color.darkened(0.45))
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_font_size_override("font_size", font_size)
