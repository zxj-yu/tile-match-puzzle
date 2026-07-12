extends Node

const SAVE_PATH = "user://savegame.json"

var data = {
	"unlocked_level": 0,
	"level_stars": {},
	"endless_best": 0,
	"total_score": 0,        # 累积总分（决定段位）
	"best_merge_level": 1,   # 达到过的最高合成等级
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

# ===== 重置 =====
func reset_save():
	data = {
		"unlocked_level": 0,
		"level_stars": {},
		"endless_best": 0,
		"total_score": 0,
		"best_merge_level": 1,
	}
	save_game()
