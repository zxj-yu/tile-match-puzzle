extends GutTest

var GM = preload("res://scripts/GridManager.gd")
var gm: Node

func before_each():
	gm = GM.new()
	gm.item_scene = load("res://scenes/Item.tscn")
	add_child_autofree(gm)

func _cell_count(layers) -> int:
	var c = 0
	for rows in layers:
		for line in rows:
			c += line.length()
	return c

# ===== 增益应用（纯函数）=====
func test_default_mods_have_expected_keys():
	var m = GM.default_rogue_mods()
	assert_eq(m["bonus_slots"], 0, "默认无额外槽位")
	assert_almost_eq(float(m["score_mult"]), 1.0, 0.001, "默认分数倍率1.0")
	assert_almost_eq(float(m["combo_cap"]), 3.0, 0.001, "默认连击上限3.0")

func test_apply_buff_slot_stacks():
	var m = GM.default_rogue_mods()
	GM.apply_buff_to(m, "slot")
	GM.apply_buff_to(m, "slot")
	assert_eq(m["bonus_slots"], 2, "两次+槽位应累加为2")

func test_apply_buff_score_and_combo():
	var m = GM.default_rogue_mods()
	GM.apply_buff_to(m, "score")
	assert_almost_eq(float(m["score_mult"]), 1.25, 0.001, "Greed 应 +25%")
	GM.apply_buff_to(m, "combo")
	assert_almost_eq(float(m["combo_cap"]), 4.0, 0.001, "Combo Surge 上限 +1")

func test_apply_buff_time_undo_shuffle():
	var m = GM.default_rogue_mods()
	GM.apply_buff_to(m, "time")
	GM.apply_buff_to(m, "undo")
	GM.apply_buff_to(m, "shuffle")
	assert_almost_eq(float(m["bonus_time"]), 15.0, 0.001)
	assert_eq(m["bonus_undo"], 2)
	assert_eq(m["bonus_shuffle"], 2)

func test_unknown_buff_is_noop():
	var m = GM.default_rogue_mods()
	GM.apply_buff_to(m, "nonexistent")
	assert_eq(m["bonus_slots"], 0, "未知增益不应改动任何字段")

# ===== 棋盘随层数递增 =====
func test_rogue_layers_escalate():
	var early = gm._rogue_layers(1)
	var late = gm._rogue_layers(6)
	assert_true(_cell_count(late) > _cell_count(early), "更高层应生成更多方块")

# ===== 增益抽取 =====
func test_random_buffs_returns_distinct_count():
	var b = gm._random_buffs(3)
	assert_eq(b.size(), 3, "应返回3个增益")
	var ids = {}
	for x in b:
		ids[x["id"]] = true
	assert_eq(ids.size(), 3, "3个增益应互不相同")
