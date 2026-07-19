extends Area2D

signal clicked

enum TileKind { NORMAL, FROZEN, STONE }

var type_id: int = 0
var kind: int = TileKind.NORMAL
var frozen_hits: int = 0     # 冰冻块还需点击的次数

# 18种: 粉5 + 蓝5 + 绿4 + 金币4
const TYPES = [
	{ "texture": preload("res://resources/items/tilePink_32.png") },
	{ "texture": preload("res://resources/items/tilePink_33.png") },
	{ "texture": preload("res://resources/items/tilePink_34.png") },
	{ "texture": preload("res://resources/items/tilePink_35.png") },
	{ "texture": preload("res://resources/items/tilePink_36.png") },
	{ "texture": preload("res://resources/items/tileBlue_32.png") },
	{ "texture": preload("res://resources/items/tileBlue_33.png") },
	{ "texture": preload("res://resources/items/tileBlue_34.png") },
	{ "texture": preload("res://resources/items/tileBlue_35.png") },
	{ "texture": preload("res://resources/items/tileBlue_36.png") },
	{ "texture": preload("res://resources/items/tileGreen_33.png") },
	{ "texture": preload("res://resources/items/tileGreen_34.png") },
	{ "texture": preload("res://resources/items/tileGreen_35.png") },
	{ "texture": preload("res://resources/items/tileGreen_36.png") },
	{ "texture": preload("res://resources/items/coin_08.png") },
	{ "texture": preload("res://resources/items/coin_09.png") },
	{ "texture": preload("res://resources/items/coin_10.png") },
	{ "texture": preload("res://resources/items/coin_11.png") },
]

@onready var bg = $Background
@onready var icon = $Icon

var is_covered_state: bool = false
var back_sprite: Sprite2D = null   # 卡背贴图
var status_label: Label = null     # ❄/🪨 状态角标
var _hint_tween: Tween = null      # 提示闪烁的循环补间

func _ready():
	input_event.connect(_on_input_event)

	# 卡背：coin_27 贴图（默认隐藏）
	back_sprite = Sprite2D.new()
	back_sprite.texture = preload("res://resources/items/coin_27.png")
	back_sprite.position = Vector2(38, 38)
	back_sprite.scale = Vector2(0.45, 0.45)   # 图偏大/偏小时调这里
	back_sprite.visible = false
	add_child(back_sprite)

	# 状态角标
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.position = Vector2(2, -4)
	status_label.visible = false
	add_child(status_label)

	_refresh_visuals()

func set_type(t: int):
	type_id = t
	_refresh_visuals()

func set_kind(k: int):
	kind = k
	if kind == TileKind.FROZEN:
		frozen_hits = 1
	_refresh_visuals()

# 冰冻块被点：返回 true 表示这次点击被"解冻"消耗掉了
func hit_frozen() -> bool:
	if kind == TileKind.FROZEN and frozen_hits > 0:
		frozen_hits -= 1
		if frozen_hits <= 0:
			kind = TileKind.NORMAL
		_refresh_visuals()
		var tw = create_tween()
		tw.tween_property(self, "position:x", position.x + 4, 0.05)
		tw.tween_property(self, "position:x", position.x - 4, 0.05)
		tw.tween_property(self, "position:x", position.x, 0.05)
		return true
	return false

func is_stone() -> bool:
	return kind == TileKind.STONE

func set_covered(is_covered: bool):
	is_covered_state = is_covered
	_refresh_visuals()

func get_main_color() -> Color:
	if type_id < 5:
		return Color(0.95, 0.5, 0.7)   # 粉
	elif type_id < 10:
		return Color(0.4, 0.65, 0.9)   # 蓝
	elif type_id < 14:
		return Color(0.5, 0.8, 0.5)    # 绿
	else:
		return Color(0.95, 0.8, 0.35)  # 金

func _refresh_visuals():
	if bg == null or icon == null:
		return

	# 石头：深灰岩石样，不参与信息隐藏
	if kind == TileKind.STONE:
		bg.color = Color(0.35, 0.33, 0.32)
		icon.visible = false
		if back_sprite: back_sprite.visible = false
		if status_label:
			status_label.text = "🪨"
			status_label.visible = true
		modulate = Color.WHITE
		return

	if is_covered_state:
		# 卡背状态：显示 coin_27 贴图，隐藏真实图案
		bg.color = Color(0.45, 0.42, 0.5)
		icon.visible = false
		if back_sprite: back_sprite.visible = true
		if status_label: status_label.visible = false
		modulate = Color.WHITE
	else:
		# 翻开状态
		icon.visible = true
		icon.texture = TYPES[type_id]["texture"]
		if back_sprite: back_sprite.visible = false
		if kind == TileKind.FROZEN:
			bg.color = Color(0.75, 0.88, 1.0)
			if status_label:
				status_label.text = "❄"
				status_label.visible = true
		else:
			bg.color = Color(1, 1, 1)
			if status_label: status_label.visible = false
		modulate = Color.WHITE

# ===== 提示闪烁：呼吸式放大 + 微微高亮，循环直到玩家操作 =====
func flash_hint():
	stop_flash()
	_hint_tween = create_tween().set_loops()
	_hint_tween.tween_property(self, "scale", Vector2(1.14, 1.14), 0.4)\
		.set_trans(Tween.TRANS_SINE)
	_hint_tween.parallel().tween_property(self, "modulate", Color(1.0, 1.0, 0.55), 0.4)
	_hint_tween.tween_property(self, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_SINE)
	_hint_tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.4)

func stop_flash():
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint_tween = null
	scale = Vector2.ONE
	modulate = Color.WHITE

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			emit_signal("clicked")
