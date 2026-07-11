class_name FloatingText
extends Label

# 用法：FloatingText.spawn(父节点, 位置, "文字", 颜色)
static func spawn(parent: Node, pos: Vector2, text: String, color: Color = Color(1, 0.85, 0.2)):
	var label = Label.new()
	label.text = text
	label.position = pos
	label.z_index = 200
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", color)
	# 加个描边让数字更清晰
	label.add_theme_color_override("font_outline_color", Color(0.3, 0.2, 0.1))
	label.add_theme_constant_override("outline_size", 4)
	parent.add_child(label)

	# 动画：往上飘 + 放大 + 淡出
	var tw = label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", pos.y - 60, 0.8)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "scale", Vector2(1.3, 1.3), 0.3)\
		.set_trans(Tween.TRANS_BACK)
	tw.tween_property(label, "modulate:a", 0.0, 0.8)\
		.set_ease(Tween.EASE_IN)
	# 动画结束销毁
	tw.chain().tween_callback(label.queue_free)
