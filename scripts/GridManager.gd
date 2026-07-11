extends Node2D

enum Mode { CAMPAIGN, ENDLESS }
var mode = Mode.CAMPAIGN

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

signal level_won(level_index: int)
signal level_won_stars(level_index: int, stars: int, time_used: float)
signal all_levels_complete
signal game_lost
signal progress_changed(remaining: int)
signal level_changed(level_index: int)
signal wave_changed(wave: int)
signal time_updated(seconds_left: float)
signal score_updated(current: int, combo: int)
signal skills_updated(slot: int, time: int, shuffle: int)

func _ready():
	_load_levels_from_json()

func _process(delta):
	if combo_count > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0

	if not timer_running or game_over or is_paused:
		return
	if mode != Mode.CAMPAIGN:
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

func _reset_skills():
	skill_slot_left = 3
	skill_time_left_count = 3
	skill_shuffle_left = 3
	emit_signal("skills_updated", skill_slot_left, skill_time_left_count, skill_shuffle_left)

func load_level(index: int):
	current_level = clamp(index, 0, campaign_levels.size() - 1)
	slot_count = BASE_SLOT_COUNT
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
	var type_count = min(4 + int(wave / 3), 15)
	var layer_count = min(2 + int(wave / 3), 4)
	var base_w = min(4 + int(wave / 2), 9)
	var base_h = min(3 + int(wave / 3), 6)

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

func _generate_board(cfg):
	var layers = cfg["layers"]
	var type_count = int(cfg["types"])

	var positions = []
	for layer_i in range(layers.size()):
		var rows_arr = layers[layer_i]
		for row_i in range(rows_arr.size()):
			var line = rows_arr[row_i]
			for col_i in range(line.length()):
				if line[col_i] == "X":
					positions.append({ "layer": layer_i, "col": col_i, "row": row_i })

	var total = positions.size()
	while total % 3 != 0:
		positions.pop_back()
		total = positions.size()

	var pool = []
	for i in range(int(total / 3)):
		var t = randi() % type_count
		for j in 3:
			pool.append(t)
	pool.shuffle()

	for p in positions:
		var item = item_scene.instantiate()
		add_child(item)
		item.set_type(pool.pop_back())
		item.position = _tile_world_pos(p)
		item.z_index = p["layer"]
		item.scale = Vector2.ZERO
		var tw = create_tween()
		tw.tween_property(item, "scale", Vector2.ONE, 0.25)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var tile = { "node": item, "layer": p["layer"], "col": p["col"], "row": p["row"] }
		item.clicked.connect(_on_tile_clicked.bind(tile))
		tiles.append(tile)

	_update_cover_states()
	emit_signal("progress_changed", tiles.size())

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
		tile["node"].set_covered(_is_covered(tile))

func _on_tile_clicked(tile):
	if game_over or click_locked or is_paused:
		return
	if _is_covered(tile):
		return
	if slots.size() >= slot_count:
		return

	click_locked = true
	_unlock_next_frame()

	SoundManager.play("click")

	tiles.erase(tile)
	_update_cover_states()
	emit_signal("progress_changed", tiles.size())
	_add_to_slots(tile["node"])

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
		text += "  连击x" + str(combo_count) + "!"
	FloatingText.spawn(self, pos, text, color)

# ===== 道具 =====
func use_skill_slot():
	if skill_slot_left <= 0 or game_over or is_paused:
		return
	skill_slot_left -= 1
	SoundManager.play("skill")
	slot_count += 1
	_draw_slot_background()
	_relayout_slots()
	emit_signal("skills_updated", skill_slot_left, skill_time_left_count, skill_shuffle_left)

func use_skill_time():
	if skill_time_left_count <= 0 or game_over or is_paused:
		return
	if mode != Mode.CAMPAIGN:
		return
	skill_time_left_count -= 1
	SoundManager.play("skill")
	time_left += 5.0
	emit_signal("time_updated", time_left)
	emit_signal("skills_updated", skill_slot_left, skill_time_left_count, skill_shuffle_left)

func use_skill_shuffle():
	if skill_shuffle_left <= 0 or game_over or is_paused:
		return
	skill_shuffle_left -= 1
	SoundManager.play("skill")
	var type_list = []
	for tile in tiles:
		type_list.append(tile["node"].type_id)
	type_list.shuffle()
	for i in range(tiles.size()):
		tiles[i]["node"].set_type(type_list[i])
	emit_signal("skills_updated", skill_slot_left, skill_time_left_count, skill_shuffle_left)

# ===== 暂停 =====
func pause_game():
	is_paused = true
	timer_running = false

func resume_game():
	is_paused = false
	if mode == Mode.CAMPAIGN and not game_over:
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
	if not tiles.is_empty():
		return
	if not slots.is_empty():
		return

	if mode == Mode.ENDLESS:
		endless_wave += 1
		_load_endless_wave()
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
