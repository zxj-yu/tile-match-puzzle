extends Node2D

enum Mode { CAMPAIGN, ENDLESS, DAILY }
var mode = Mode.CAMPAIGN

# 战役和每日都是限时模式，无尽不限时
func _is_timed() -> bool:
	return mode == Mode.CAMPAIGN or mode == Mode.DAILY

const CELL_SIZE = 76
const GRID_ORIGIN = Vector2(60, 130)
var slot_count = 7
const BASE_SLOT_COUNT = 7
const SLOT_SIZE = 80
const SLOT_Y = 620

@export var item_scene: PackedScene

var campaign_levels = []
var current_level: int = 0
var endless_wave: int = 0

var tiles = []
var slots = []
var game_over = false
var is_paused = false
var bg_nodes = []
var click_locked = false

# 挂机提示：闲置超过 HINT_IDLE_TIME 秒就闪烁可消除的方块
const HINT_IDLE_TIME := 4.0
var idle_time := 0.0
var hint_active := false
var hint_nodes := []

var time_left: float = 0.0
var timer_running: bool = false
var current_time_limit: float = 0.0

var current_score: int = 0
var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW = 2.0

var skill_slot_left: int = 3
var skill_time_left_count: int = 3
var skill_shuffle_left: int = 3
var skill_undo_left: int = 3
# 撤销栈：存被收进托盘的方块字典（与 tiles 里同一个引用），可原样放回棋盘
var undo_stack = []

signal level_won(level_index: int)
signal level_won_stars(level_index: int, stars: int, time_used: float)
signal all_levels_complete
signal game_lost
signal progress_changed(remaining: int)
signal level_changed(level_index: int)
signal wave_changed(wave: int)
signal time_updated(seconds_left: float)
signal score_updated(current: int, combo: int)
signal skills_updated(slot: int, time: int, shuffle: int, undo: int)
signal daily_won(time_used: float)

func _ready():
	_load_levels_from_json()

func _process(delta):
	if combo_count > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0

	# 挂机提示：棋盘处于可玩状态时累计闲置时间（战役/无尽都适用）
	if not game_over and not is_paused and tiles.size() > 0:
		idle_time += delta
		if idle_time >= HINT_IDLE_TIME and not hint_active:
			_show_hint()
	else:
		_reset_idle()

	if not timer_running or game_over or is_paused:
		return
	if not _is_timed():
		return
	time_left -= delta
	emit_signal("time_updated", time_left)
	if time_left <= 0:
		time_left = 0
		timer_running = false
		game_over = true
		SoundManager.play("lose")
		emit_signal("game_lost")

func _load_levels_from_json():
	var path = "res://levels.json"
	if not FileAccess.file_exists(path):
		push_error("找不到 levels.json")
		return
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		push_error("levels.json 解析失败: " + json.get_error_message())
		return
	campaign_levels = json.data["levels"]
	print("成功加载 ", campaign_levels.size(), " 个关卡")

func start_campaign():
	mode = Mode.CAMPAIGN
	var unlocked = SaveManager.data["unlocked_level"]
	current_level = clamp(unlocked, 0, campaign_levels.size() - 1)
	load_level(current_level)

func start_level(index: int):
	mode = Mode.CAMPAIGN
	load_level(index)

func start_endless():
	mode = Mode.ENDLESS
	endless_wave = 0
	timer_running = false
	_load_endless_wave()

# ===== 每日挑战：用当天日期做种子，全员同一局 =====
# 纯函数，便于测试：给定年月日返回确定的种子
func daily_seed_for(year: int, month: int, day: int) -> int:
	return year * 10000 + month * 100 + day

func _daily_seed() -> int:
	var d = Time.get_date_dict_from_system()
	return daily_seed_for(int(d.year), int(d.month), int(d.day))

# 固定形状（3 层递减矩形），保证有挖层深度；花色由种子决定
func _daily_layout() -> Array:
	return [
		["XXXXXXXX", "XXXXXXXX", "XXXXXXXX", "XXXXXXXX"],  # 层0
		["XXXXXX", "XXXXXX", "XXXXXX"],                     # 层1
		["XXXX", "XXXX"],                                   # 层2
	]

func start_daily():
	mode = Mode.DAILY
	current_level = 0
	slot_count = BASE_SLOT_COUNT
	_clear_board()
	_draw_slot_background()
	game_over = false
	is_paused = false
	current_score = 0
	combo_count = 0
	_reset_skills()

	seed(_daily_seed())                              # 固定种子 → 确定性棋盘
	_generate_board({ "types": 6, "layers": _daily_layout() })
	randomize()                                      # 生成完立刻恢复随机，避免影响后续模式

	current_time_limit = 180.0
	time_left = current_time_limit
	timer_running = true
	emit_signal("time_updated", time_left)
	emit_signal("progress_changed", _count_playable())

func _reset_skills():
	skill_slot_left = 3
	skill_time_left_count = 3
	skill_shuffle_left = 3
	skill_undo_left = 3
	undo_stack = []
	emit_signal("skills_updated", skill_slot_left, skill_time_left_count, skill_shuffle_left, skill_undo_left)

func load_level(index: int):
	current_level = clamp(index, 0, campaign_levels.size() - 1)
	var cfg_pre = campaign_levels[clamp(index, 0, campaign_levels.size() - 1)]
	slot_count = int(cfg_pre.get("slot_count", BASE_SLOT_COUNT))
	_clear_board()
	var cfg = campaign_levels[current_level]
	_generate_board(cfg)
	_draw_slot_background()
	game_over = false
	is_paused = false
	current_score = 0
	combo_count = 0
	_reset_skills()
	current_time_limit = float(cfg.get("time_limit", 120))
	time_left = current_time_limit
	timer_running = true
	emit_signal("time_updated", time_left)
	emit_signal("level_changed", current_level)

func next_level():
	if current_level + 1 < campaign_levels.size():
		load_level(current_level + 1)

func retry_level():
	if mode == Mode.ENDLESS:
		start_endless()
	elif mode == Mode.DAILY:
		start_daily()
	else:
		load_level(current_level)

func _load_endless_wave():
	slot_count = BASE_SLOT_COUNT
	_clear_board()
	_draw_slot_background()
	game_over = false
	is_paused = false
	timer_running = false
	current_score = 0
	combo_count = 0
	_reset_skills()

	var wave = endless_wave
	var type_count = min(4 + int(wave / 2), 18)
	var layer_count = min(2 + int(wave / 3), 3)
	var base_w = min(6 + wave, 12)
	var base_h = min(4 + int(wave / 2), 6)

	var layers = []
	for layer in range(layer_count):
		var w = max(2, base_w - layer)
		var h = max(2, base_h - layer)
		var rows_arr = []
		for r in range(h):
			var line = ""
			for c in range(w):
				line += "X"
			rows_arr.append(line)
		layers.append(rows_arr)

	_generate_board({ "types": type_count, "layers": layers })
	emit_signal("wave_changed", wave + 1)

func _clear_board():
	for t in tiles:
		t["node"].queue_free()
	tiles = []
	for it in slots:
		it.queue_free()
	slots = []
	for bg in bg_nodes:
		bg.queue_free()
	bg_nodes = []
	undo_stack = []
	# 重置提示状态（节点即将释放，不再引用）
	hint_nodes = []
	hint_active = false
	idle_time = 0.0

func _generate_board(cfg):
	var layers = cfg["layers"]
	var type_count = int(cfg["types"])

	var positions = []
	for layer_i in range(layers.size()):
		var rows_arr = layers[layer_i]
		for row_i in range(rows_arr.size()):
			var line = rows_arr[row_i]
			for col_i in range(line.length()):
				var ch = line[col_i]
				# 石头功能已取消：布局里的 "S" 一律当作普通方块，避免永久遮挡卡死
				if ch == "S":
					ch = "X"
				if ch == "X" or ch == "I":
					positions.append({
						"layer": layer_i, "col": col_i, "row": row_i,
						"kind": ch
					})

	# 可玩方块（X+I）数量校验，石头不算
	var playable = []
	var stones = []
	for p in positions:
		if p["kind"] == "S":
			stones.append(p)
		else:
			playable.append(p)
	while playable.size() % 3 != 0:
		playable.pop_back()

	var pool = []
	for i in range(int(playable.size() / 3)):
		var t = randi() % type_count
		for j in 3:
			pool.append(t)
	pool.shuffle()

	# 生成可玩方块
	for p in playable:
		var item = item_scene.instantiate()
		add_child(item)
		item.set_type(pool.pop_back())
		if p["kind"] == "I":
			item.set_kind(item.TileKind.FROZEN)
		item.position = _tile_world_pos(p)
		item.z_index = p["layer"]
		item.scale = Vector2.ZERO
		var tw = create_tween()
		tw.tween_property(item, "scale", Vector2.ONE, 0.25)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var tile = { "node": item, "layer": p["layer"], "col": p["col"], "row": p["row"] }
		item.clicked.connect(_on_tile_clicked.bind(tile))
		tiles.append(tile)

	# 生成石头（不进 pool，不可点击拿取，但参与遮挡）
	for p in stones:
		var item = item_scene.instantiate()
		add_child(item)
		item.set_kind(item.TileKind.STONE)
		item.position = _tile_world_pos(p)
		item.z_index = p["layer"]
		var tile = { "node": item, "layer": p["layer"], "col": p["col"], "row": p["row"] }
		item.clicked.connect(_on_tile_clicked.bind(tile))
		tiles.append(tile)

	_update_cover_states()
	emit_signal("progress_changed", _count_playable())

func _count_playable() -> int:
	var c = 0
	for t in tiles:
		if not t["node"].is_stone():
			c += 1
	return c
func _tile_world_pos(p) -> Vector2:
	var offset = Vector2.ZERO
	if int(p["layer"]) % 2 == 1:
		offset = Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
	return GRID_ORIGIN + Vector2(p["col"] * CELL_SIZE, p["row"] * CELL_SIZE) + offset

func _is_covered(tile) -> bool:
	var ax = tile["col"] + (0.5 if int(tile["layer"]) % 2 == 1 else 0.0)
	var ay = tile["row"] + (0.5 if int(tile["layer"]) % 2 == 1 else 0.0)
	for other in tiles:
		if other["layer"] <= tile["layer"]:
			continue
		var bx = other["col"] + (0.5 if int(other["layer"]) % 2 == 1 else 0.0)
		var by = other["row"] + (0.5 if int(other["layer"]) % 2 == 1 else 0.0)
		if abs(ax - bx) < 1.0 and abs(ay - by) < 1.0:
			return true
	return false

func _update_cover_states():
	for tile in tiles:
		var node = tile["node"]
		var was_covered = node.is_covered_state
		var now_covered = _is_covered(tile)
		if was_covered and not now_covered:
			# 刚被翻开：翻牌动画
			node.set_covered(false)
			node.scale = Vector2(0.1, 1.0)
			var tw = create_tween()
			tw.tween_property(node, "scale", Vector2.ONE, 0.2)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			node.set_covered(now_covered)

func _on_tile_clicked(tile):
	if game_over or click_locked or is_paused:
		return
	if _is_covered(tile):
		return
	_reset_idle()  # 有操作，重置挂机计时并清掉提示
	var node = tile["node"]
	# 石头永远不可拿
	if node.is_stone():
		return
	# 冰冻块：第一次点击是解冻，不进槽
	if node.hit_frozen():
		SoundManager.play("click")
		click_locked = true
		_unlock_next_frame()
		return
	if slots.size() >= slot_count:
		return

	click_locked = true
	_unlock_next_frame()

	SoundManager.play("click")

	# 记录这次取牌，供撤销道具回退（存的是同一个 tile 字典引用）
	undo_stack.append(tile)
	tiles.erase(tile)
	_update_cover_states()
	emit_signal("progress_changed", _count_playable())
	_add_to_slots(node)

func _unlock_next_frame():
	await get_tree().process_frame
	click_locked = false

func _slot_origin() -> Vector2:
	return Vector2(GRID_ORIGIN.x, SLOT_Y)

func _draw_slot_background():
	for bg in bg_nodes:
		bg.queue_free()
	bg_nodes = []
	for i in slot_count:
		var bg = ColorRect.new()
		bg.size = Vector2(SLOT_SIZE - 10, SLOT_SIZE - 10)
		bg.position = _slot_origin() + Vector2(i * SLOT_SIZE, 0) + Vector2(5, 5)
		bg.color = Color(0.82, 0.78, 0.70, 0.9)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.z_index = 50
		add_child(bg)
		bg_nodes.append(bg)

func _add_to_slots(item):
	item.set_covered(false)
	item.z_index = 100
	var insert_idx = slots.size()
	for i in range(slots.size()):
		if slots[i].type_id == item.type_id:
			insert_idx = i + 1
	slots.insert(insert_idx, item)
	_relayout_slots()

	await get_tree().create_timer(0.25).timeout
	if game_over:
		return
	var eliminated = _check_triples()
	if not eliminated and slots.size() >= slot_count:
		game_over = true
		timer_running = false
		if mode == Mode.ENDLESS:
			SaveManager.record_endless(endless_wave)
		SoundManager.play("lose")
		emit_signal("game_lost")
		return
	_check_win()

func _relayout_slots():
	for i in range(slots.size()):
		var target = _slot_origin() + Vector2(i * SLOT_SIZE, 0)
		var tw = create_tween()
		tw.tween_property(slots[i], "position", target, 0.2)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _check_triples() -> bool:
	for i in range(slots.size() - 2):
		if slots[i].type_id == slots[i + 1].type_id \
		and slots[i].type_id == slots[i + 2].type_id:
			var trio = [slots[i], slots[i + 1], slots[i + 2]]
			var center = trio[1].position
			var burst_color = trio[1].get_main_color()

			# 三消发生：被消掉的方块已释放，撤销栈失效，清空
			undo_stack = []

			for it in trio:
				slots.erase(it)
				BurstParticle.spawn(self, it.position, burst_color)
				var tw = create_tween()
				tw.tween_property(it, "scale", Vector2.ZERO, 0.2)
				tw.tween_callback(it.queue_free)

			_relayout_slots()
			_award_score_with_effect(center)
			return true
	return false

func _award_score_with_effect(pos: Vector2):
	combo_count += 1
	combo_timer = COMBO_WINDOW
	var mult = min(1.0 + (combo_count - 1) * 0.5, 3.0)
	var points = int(100 * mult)
	current_score += points
	SaveManager.add_score(points)
	emit_signal("score_updated", current_score, combo_count)

	if combo_count >= 3:
		SoundManager.play("combo")
	else:
		SoundManager.play("match")

	var text = "+" + str(points)
	var color = Color(1, 0.85, 0.2)
	if combo_count >= 3:
		color = Color(1, 0.4, 0.3)
		text += "  Combo x" + str(combo_count) + "!"
	FloatingText.spawn(self, pos, text, color)

# ===== 道具 =====
func use_skill_slot():
	if skill_slot_left <= 0 or game_over or is_paused:
		return
	_reset_idle()
	skill_slot_left -= 1
	SoundManager.play("skill")
	slot_count += 1
	_draw_slot_background()
	_relayout_slots()
	emit_signal("skills_updated", skill_slot_left, skill_time_left_count, skill_shuffle_left, skill_undo_left)

func use_skill_time():
	if skill_time_left_count <= 0 or game_over or is_paused:
		return
	if not _is_timed():
		return
	_reset_idle()
	skill_time_left_count -= 1
	SoundManager.play("skill")
	time_left += 5.0
	emit_signal("time_updated", time_left)
	emit_signal("skills_updated", skill_slot_left, skill_time_left_count, skill_shuffle_left, skill_undo_left)

func use_skill_shuffle():
	if skill_shuffle_left <= 0 or game_over or is_paused:
		return
	_reset_idle()
	skill_shuffle_left -= 1
	SoundManager.play("skill")
	# 只打乱可玩方块，跳过石头
	var playable_tiles = []
	for tile in tiles:
		if not tile["node"].is_stone():
			playable_tiles.append(tile)
	var type_list = []
	for tile in playable_tiles:
		type_list.append(tile["node"].type_id)
	type_list.shuffle()
	for i in range(playable_tiles.size()):
		playable_tiles[i]["node"].set_type(type_list[i])
	emit_signal("skills_updated", skill_slot_left, skill_time_left_count, skill_shuffle_left, skill_undo_left)

func use_skill_undo():
	if skill_undo_left <= 0 or game_over or is_paused:
		return
	if undo_stack.is_empty():
		return
	var tile = undo_stack.pop_back()
	var node = tile["node"]
	# 只有还留在托盘里的方块才能撤销（已被三消掉的不行）
	if not slots.has(node):
		return
	_reset_idle()
	skill_undo_left -= 1
	SoundManager.play("skill")
	# 从托盘取出，原样放回棋盘的原位置和层级
	slots.erase(node)
	node.z_index = tile["layer"]
	node.position = _tile_world_pos(tile)
	# 用回原来的 tile 字典引用，原有的 clicked 绑定依然有效，无需重连
	tiles.append(tile)
	_relayout_slots()
	_update_cover_states()
	emit_signal("progress_changed", _count_playable())
	emit_signal("skills_updated", skill_slot_left, skill_time_left_count, skill_shuffle_left, skill_undo_left)

# ===== 挂机提示 =====
func _reset_idle():
	idle_time = 0.0
	if hint_active:
		_clear_hint()

func _clear_hint():
	for n in hint_nodes:
		if is_instance_valid(n):
			n.stop_flash()
	hint_nodes = []
	hint_active = false

# 找出最值得提示的一组同类方块（纯逻辑，便于测试）
func _find_hint_tiles() -> Array:
	# 统计每种未遮挡（可点）方块
	var by_type := {}
	for tile in tiles:
		if _is_covered(tile):
			continue
		var node = tile["node"]
		if not by_type.has(node.type_id):
			by_type[node.type_id] = []
		by_type[node.type_id].append(node)
	# 统计托盘里已有的类型，优先提示“差一步就能消”的
	var tray := {}
	for it in slots:
		tray[it.type_id] = tray.get(it.type_id, 0) + 1

	var best := []
	var best_need := 99
	for tid in by_type.keys():
		var avail = by_type[tid].size()
		var have = int(tray.get(tid, 0))
		if have + avail >= 3:
			var need = max(1, 3 - have)     # 还需要从棋盘拿几张
			var take = min(need, avail)
			if take > 0 and need < best_need:
				best_need = need
				best = by_type[tid].slice(0, take)
	# 退路：没有能立刻凑成三消的，就高亮同类最多的一组（>=2）引导玩家往这凑
	if best.is_empty():
		var best_count := 1
		for tid in by_type.keys():
			if by_type[tid].size() > best_count:
				best_count = by_type[tid].size()
				best = by_type[tid].slice(0, min(3, by_type[tid].size()))
	return best

func _show_hint():
	var nodes = _find_hint_tiles()
	if nodes.is_empty():
		return
	hint_nodes = nodes
	hint_active = true
	for n in nodes:
		n.flash_hint()

# ===== 暂停 =====
func pause_game():
	is_paused = true
	timer_running = false

func resume_game():
	is_paused = false
	_reset_idle()  # 刚恢复不要立刻弹提示
	if _is_timed() and not game_over:
		timer_running = true

func quit_to_title():
	is_paused = false
	timer_running = false
	game_over = true
	_clear_board()

# ===== 胜利判定 =====
func _check_win():
	if game_over:
		return
	if _count_playable() > 0:
		return
	if not slots.is_empty():
		return

	if mode == Mode.ENDLESS:
		endless_wave += 1
		_load_endless_wave()
		return

	if mode == Mode.DAILY:
		game_over = true
		timer_running = false
		SoundManager.play("win")
		var t = current_time_limit - time_left
		SaveManager.record_daily(t)
		emit_signal("daily_won", t)
		return

	game_over = true
	timer_running = false
	SoundManager.play("win")
	var time_used = current_time_limit - time_left
	var stars = _calc_stars(time_used)
	SaveManager.record_level_clear(current_level, stars)
	if current_level == campaign_levels.size() - 1:
		emit_signal("all_levels_complete")
	else:
		emit_signal("level_won_stars", current_level, stars, time_used)

func _calc_stars(time_used: float) -> int:
	var cfg = campaign_levels[current_level]
	var st = cfg.get("star_times", [999, 999, 999])
	if time_used <= float(st[0]):
		return 3
	elif time_used <= float(st[1]):
		return 2
	else:
		return 1
