extends Node

const SAVE_PATH = "user://savegame.json"

var data = {
	"unlocked_level": 0,
	"level_stars": {},
	"endless_best": 0,
	"total_score": 0,        # 累积总分（决定段位）
	"best_merge_level": 1,   # 达到过的最高合成等级
	"bgm_volume": 0.6,       # 背景音乐音量（线性 0~1）
	"sfx_volume": 1.0,       # 音效音量（线性 0~1）
	"muted": false,          # 总静音
	"achievements": [],      # 已解锁成就 id 列表
	"daily_date": "",        # 最近一次每日挑战的日期 (YYYY-MM-DD)
	"daily_best_time": 0.0,  # 当日最好通关用时（秒），0 表示今天还没通关
	"rogue_best_stage": 0,   # Roguelite 到达过的最高层数
	"rogue_best_score": 0,   # Roguelite 单局最高分
}

# 段位定义
const RANKS = [
	{ "name": "Bronze", "min": 0 },
	{ "name": "Silver", "min": 3000 },
	{ "name": "Gold", "min": 8000 },
	{ "name": "Platinum", "min": 18000 },
	{ "name": "Diamond", "min": 35000 },
	{ "name": "Master", "min": 60000 },
	{ "name": "King", "min": 100000 },
]

func _ready():
	load_game()

# ===== 读写 =====
func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("无存档，使用默认值")
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(text) == OK:
		var loaded = json.data
		for key in data.keys():
			if loaded.has(key):
				data[key] = loaded[key]
		print("存档已加载：", data)
	else:
		print("存档解析失败，使用默认值")

func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

# ===== 闯关进度 =====
func record_level_clear(level_index: int, stars: int):
	if level_index + 1 > data["unlocked_level"]:
		data["unlocked_level"] = level_index + 1
	var key = str(level_index)
	var old_stars = data["level_stars"].get(key, 0)
	if stars > old_stars:
		data["level_stars"][key] = stars
	save_game()

func get_level_stars(level_index: int) -> int:
	return data["level_stars"].get(str(level_index), 0)

# ===== 关卡地图：顺序解锁 + 星星门槛 =====
func total_stars() -> int:
	var t = 0
	for k in data["level_stars"].keys():
		t += int(data["level_stars"][k])
	return t

const SECTION_SIZE = 5
# 每 5 关一段，进入该段所需的累计星数门槛
const STAR_GATES = [0, 6, 15, 27, 42, 60]

func star_gate_for(index: int) -> int:
	var section = int(index / SECTION_SIZE)
	if section < STAR_GATES.size():
		return STAR_GATES[section]
	# 超出预设段落时线性外推
	return STAR_GATES[STAR_GATES.size() - 1] + (section - STAR_GATES.size() + 1) * 20

# 关卡是否可玩：既要顺序解锁到位，又要累计星数达到门槛
func is_level_unlocked(index: int) -> bool:
	if index > int(data["unlocked_level"]):
		return false
	return total_stars() >= star_gate_for(index)

# ===== 无尽 =====
func record_endless(wave: int):
	if wave > data["endless_best"]:
		data["endless_best"] = wave
		save_game()

# ===== 分数与段位 =====
func add_score(points: int):
	data["total_score"] += points
	save_game()

func get_rank() -> String:
	var score = data["total_score"]
	var rank_name = RANKS[0]["name"]
	for r in RANKS:
		if score >= r["min"]:
			rank_name = r["name"]
	return rank_name

func get_next_rank_info():
	var score = data["total_score"]
	for r in RANKS:
		if score < r["min"]:
			return { "name": r["name"], "needed": r["min"] - score }
	return { "name": "已封顶", "needed": 0 }

# ===== 合成里程碑 =====
func record_merge_level(lv: int) -> bool:
	if lv > data["best_merge_level"]:
		data["best_merge_level"] = lv
		save_game()
		return true
	return false

# ===== 每日挑战 =====
func today_string() -> String:
	var d = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]

# 记录一次每日挑战通关：换了新的一天则重置，否则只保留更快的成绩
func record_daily(time_used: float):
	var today = today_string()
	if str(data.get("daily_date", "")) != today:
		data["daily_date"] = today
		data["daily_best_time"] = time_used
	else:
		var best = float(data.get("daily_best_time", 0.0))
		if best <= 0.0 or time_used < best:
			data["daily_best_time"] = time_used
	save_game()

func daily_done_today() -> bool:
	return str(data.get("daily_date", "")) == today_string() \
		and float(data.get("daily_best_time", 0.0)) > 0.0

# 今天的最好用时；今天还没通关则返回 0.0
func get_daily_best() -> float:
	if daily_done_today():
		return float(data["daily_best_time"])
	return 0.0

# ===== Roguelite 记录 =====
# 分别保留最高层数与最高单局分
func record_rogue(stage: int, score: int):
	var changed = false
	if stage > int(data.get("rogue_best_stage", 0)):
		data["rogue_best_stage"] = stage
		changed = true
	if score > int(data.get("rogue_best_score", 0)):
		data["rogue_best_score"] = score
		changed = true
	if changed:
		save_game()

# ===== 重置 =====
func reset_save():
	data = {
		"unlocked_level": 0,
		"level_stars": {},
		"endless_best": 0,
		"total_score": 0,
		"best_merge_level": 1,
		"bgm_volume": 0.6,
		"sfx_volume": 1.0,
		"muted": false,
		"achievements": [],
		"daily_date": "",
		"daily_best_time": 0.0,
		"rogue_best_stage": 0,
		"rogue_best_score": 0,
	}
	save_game()
