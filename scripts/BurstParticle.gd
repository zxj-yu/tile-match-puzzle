class_name BurstParticle
extends Node2D

# 用法：BurstParticle.spawn(父节点, 位置, 颜色)
static func spawn(parent: Node, pos: Vector2, base_color: Color = Color(1, 0.8, 0.3)):
	var count = 8  # 8个粒子四散
	for i in range(count):
		var particle = ColorRect.new()
		var size = randf_range(8, 16)
		particle.size = Vector2(size, size)
		particle.color = base_color
		particle.position = pos
		particle.pivot_offset = particle.size / 2
		particle.z_index = 190
		parent.add_child(particle)

		# 随机方向飞散
		var angle = (TAU / count) * i + randf_range(-0.3, 0.3)
		var distance = randf_range(40, 80)
		var target = pos + Vector2(cos(angle), sin(angle)) * distance

		var tw = particle.create_tween()
		tw.set_parallel(true)
		# 飞出去
		tw.tween_property(particle, "position", target, 0.5)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# 旋转
		tw.tween_property(particle, "rotation", randf_range(-PI, PI), 0.5)
		# 缩小消失
		tw.tween_property(particle, "scale", Vector2.ZERO, 0.5)\
			.set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(particle.queue_free)
