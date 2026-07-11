extends Area2D

signal clicked

var type_id: int = 0

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
	{ "texture": preload("res://resources/items/coin_11.png") },
]

@onready var bg = $Background
@onready var icon = $Icon

func _ready():
	input_event.connect(_on_input_event)
	_refresh_visuals()

func set_type(t: int):
	type_id = t
	_refresh_visuals()

func set_covered(is_covered: bool):
	if is_covered:
		modulate = Color(0.5, 0.5, 0.5)
	else:
		modulate = Color.WHITE

# 返回代表色（用于粒子特效）
func get_main_color() -> Color:
	if type_id < 5:
		return Color(0.95, 0.5, 0.7)   # 粉系
	elif type_id < 10:
		return Color(0.4, 0.65, 0.9)   # 蓝系
	else:
		return Color(0.5, 0.8, 0.5)    # 绿系

func _refresh_visuals():
	if bg == null or icon == null:
		return
	bg.color = Color(1, 1, 1)
	icon.texture = TYPES[type_id]["texture"]

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			emit_signal("clicked")
