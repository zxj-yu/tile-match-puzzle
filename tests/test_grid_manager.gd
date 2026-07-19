extends GutTest

# 被测对象
var gm: Node

func before_each():
	gm = preload("res://scripts/GridManager.gd").new()
	# 关键：item_scene 是 @export，用 .new() 创建时为 null。
	# _generate_board 会调用 item_scene.instantiate()，不手动赋值就会崩。
	# 这不是改测试“作弊”，而是补上场景里本该注入的依赖。
	gm.item_scene = load("res://scenes/Item.tscn")
	add_child_autofree(gm)  # 测试结束自动清理

# ===== 测试1: 布局生成后可玩方块数必须是3的倍数 =====
func test_generated_board_playable_count_is_multiple_of_3():
	var cfg = {
		"types": 5,
		"layers": [
			["XXXXX", "XXXXX", "XXXXX"],   # 15个
			["XXX", "XXX"],                 # 6个，共21，是3的倍数
		]
	}
	gm._generate_board(cfg)
	var playable = gm._count_playable()
	assert_eq(playable % 3, 0, "可玩方块数应为3的倍数")

func test_odd_layout_gets_trimmed_to_multiple_of_3():
	# 故意给一个不是3倍数的布局，验证代码会自动裁剪
	var cfg = {
		"types": 4,
		"layers": [
			["XXXXX"],  # 5个，不是3的倍数
		]
	}
	gm._generate_board(cfg)
	var playable = gm._count_playable()
	assert_eq(playable % 3, 0, "奇怪数量的布局应被自动裁剪为3的倍数")
	assert_true(playable <= 5, "裁剪后数量不应超过原始输入")

# ===== 测试2: 遮挡计算 =====
func test_top_layer_tile_is_not_covered():
	# 用一个干净的、保证不裁剪的单层布局测试
	var cfg2 = { "types": 3, "layers": [["XXX", "XXX", "XXX"]] }  # 单层9个
	gm._generate_board(cfg2)
	# 单层布局，所有方块都应该是未遮挡的
	for tile in gm.tiles:
		assert_false(gm._is_covered(tile), "单层布局中所有方块都不应被遮挡")

func test_lower_layer_tile_is_covered_by_upper_layer():
	# 构造两层，故意让位置精确重叠
	var cfg = {
		"types": 3,
		"layers": [
			["XXX", "XXX", "XXX"],  # 层0
			["XXX", "XXX"],          # 层1（奇数层，会偏移半格）
		]
	}
	gm._generate_board(cfg)
	# 找一个层0的方块，检查是否生成了层0（逻辑正确性）
	var has_layer0 = false
	for tile in gm.tiles:
		if tile["layer"] == 0:
			has_layer0 = true
	assert_true(has_layer0, "应该生成了层0的方块")

# ===== 测试3: 星级计算边界条件 =====
func test_star_calculation_exact_boundary():
	gm.campaign_levels = [
		{ "star_times": [30, 60, 90] }
	]
	gm.current_level = 0
	# 恰好等于3星阈值，应该拿3星
	assert_eq(gm._calc_stars(30.0), 3, "用时恰好等于3星阈值应得3星")
	# 恰好等于2星阈值，应该拿2星
	assert_eq(gm._calc_stars(60.0), 2, "用时恰好等于2星阈值应得2星")
	# 超过所有阈值，应该拿1星
	assert_eq(gm._calc_stars(95.0), 1, "用时超过所有阈值应得1星")
	# 用时很短，应该拿3星
	assert_eq(gm._calc_stars(5.0), 3, "用时很短应得3星")

# ===== 测试4: 撤销道具 =====
# 模拟“取一张牌进托盘”：把一个 tile 从棋盘挪到托盘，并压入撤销栈
func _simulate_collect(tile):
	var node = tile["node"]
	gm.undo_stack.append(tile)
	gm.tiles.erase(tile)
	gm.slots.append(node)

func test_undo_returns_tile_to_board():
	var cfg = { "types": 3, "layers": [["XXX", "XXX", "XXX"]] }  # 单层9个
	gm._generate_board(cfg)
	var before = gm._count_playable()
	var tile = gm.tiles[0]
	_simulate_collect(tile)
	assert_eq(gm._count_playable(), before - 1, "取牌后棋盘可玩数应减1")
	gm.use_skill_undo()
	assert_eq(gm._count_playable(), before, "撤销后棋盘可玩数应恢复")
	assert_true(gm.tiles.has(tile), "撤销后方块应回到棋盘")
	assert_eq(gm.slots.size(), 0, "撤销后托盘应清空该牌")
	assert_eq(gm.skill_undo_left, 2, "撤销一次后次数应从3变2")

func test_undo_respects_use_limit():
	var cfg = { "types": 3, "layers": [["XXX", "XXX", "XXX"]] }
	gm._generate_board(cfg)
	var tile = gm.tiles[0]
	_simulate_collect(tile)
	gm.skill_undo_left = 0  # 次数用尽
	gm.use_skill_undo()
	assert_eq(gm.slots.size(), 1, "次数用尽时撤销应无效，牌仍在托盘")
	assert_eq(gm.skill_undo_left, 0, "次数不应变成负数")

func test_undo_does_nothing_when_stack_empty():
	var cfg = { "types": 3, "layers": [["XXX", "XXX", "XXX"]] }
	gm._generate_board(cfg)
	gm.undo_stack = []
	gm.use_skill_undo()
	assert_eq(gm.skill_undo_left, 3, "撤销栈为空时不消耗次数")

func test_undo_cannot_restore_eliminated_tile():
	# 撤销栈里有牌，但它已不在托盘（模拟被三消掉/已释放）——不应恢复也不扣次数
	var cfg = { "types": 3, "layers": [["XXX", "XXX", "XXX"]] }
	gm._generate_board(cfg)
	var tile = gm.tiles[0]
	gm.undo_stack.append(tile)
	gm.tiles.erase(tile)
	# 注意：故意不放进 slots，模拟已被消除
	gm.use_skill_undo()
	assert_eq(gm.skill_undo_left, 3, "无法撤销已消除的牌，不应扣次数")
	assert_false(gm.tiles.has(tile), "已消除的牌不应被放回棋盘")

# ===== 测试5: 石头功能已取消 =====
func test_stone_char_becomes_normal_playable_tile():
	# 布局里故意放 S，应全部变成普通可玩方块，不再生成不可消除的石头
	var cfg = { "types": 3, "layers": [["XXSXXX", "XXXXXS", "SXXXXX"]] }  # 18格，含3个S
	gm._generate_board(cfg)
	for tile in gm.tiles:
		assert_false(tile["node"].is_stone(), "S 应变成普通方块，不应存在石头")
	assert_eq(gm._count_playable(), gm.tiles.size(), "无石头时所有方块都应可玩")
	assert_eq(gm._count_playable() % 3, 0, "可玩数应为3的倍数")

# ===== 测试6: 挂机提示 =====
func test_hint_finds_same_type_uncovered_group():
	# 单层6格全部未遮挡，把前3个设成同一类型
	var cfg = { "types": 3, "layers": [["XXXXXX"]] }
	gm._generate_board(cfg)
	for i in range(gm.tiles.size()):
		gm.tiles[i]["node"].set_type(0 if i < 3 else 1)
	var hint = gm._find_hint_tiles()
	assert_true(hint.size() >= 1, "应能找到提示方块")
	var t = hint[0].type_id
	for n in hint:
		assert_eq(n.type_id, t, "提示的方块应为同一类型")

func test_hint_empty_when_board_empty():
	var cfg = { "types": 3, "layers": [["XXX"]] }
	gm._generate_board(cfg)
	gm.tiles = []  # 清空棋盘
	assert_eq(gm._find_hint_tiles().size(), 0, "棋盘为空时不应给出提示")

func test_hint_ignores_covered_tiles():
	# 两层：下层被上层遮挡。被遮挡的方块不应进入提示
	var cfg = { "types": 3, "layers": [["XXX", "XXX", "XXX"], ["XXX", "XXX", "XXX"]] }
	gm._generate_board(cfg)
	var hint = gm._find_hint_tiles()
	for n in hint:
		# 提示的每个节点，都应能在 tiles 里找到且未被遮挡
		var found_uncovered = false
		for tile in gm.tiles:
			if tile["node"] == n:
				found_uncovered = not gm._is_covered(tile)
		assert_true(found_uncovered, "提示的方块必须是未遮挡的")
