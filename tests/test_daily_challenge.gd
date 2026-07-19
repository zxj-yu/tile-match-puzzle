extends GutTest

var gm: Node

func before_each():
	gm = preload("res://scripts/GridManager.gd").new()
	gm.item_scene = load("res://scenes/Item.tscn")
	add_child_autofree(gm)

func _type_sequence() -> Array:
	var seq = []
	for t in gm.tiles:
		seq.append(t["node"].type_id)
	return seq

# ===== 种子确定性 =====
func test_daily_seed_is_deterministic():
	assert_eq(gm.daily_seed_for(2026, 7, 18), gm.daily_seed_for(2026, 7, 18), "同一天应得到相同种子")

func test_daily_seed_differs_by_date():
	assert_ne(gm.daily_seed_for(2026, 7, 18), gm.daily_seed_for(2026, 7, 19), "不同日期种子应不同")

# ===== 棋盘可复现 =====
func test_same_seed_produces_identical_board():
	var cfg = { "types": 6, "layers": [["XXXXXX", "XXXXXX", "XXXXXX"]] }
	seed(4242)
	gm._generate_board(cfg)
	var seq1 = _type_sequence()
	gm._clear_board()
	seed(4242)
	gm._generate_board(cfg)
	var seq2 = _type_sequence()
	assert_eq(seq1, seq2, "同一种子应生成完全相同的方块序列")

func test_different_seed_changes_board():
	var cfg = { "types": 6, "layers": [["XXXXXX", "XXXXXX", "XXXXXX"]] }
	seed(1)
	gm._generate_board(cfg)
	var seq1 = _type_sequence()
	gm._clear_board()
	seed(2)
	gm._generate_board(cfg)
	var seq2 = _type_sequence()
	assert_ne(seq1, seq2, "不同种子应生成不同序列")
