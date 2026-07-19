extends Node
# 成就系统（自动加载单例）。定义成就、判断解锁、写入存档，
# 解锁时发出信号供 UI 弹出提示。所有条件判断都是纯逻辑，便于单元测试。

signal achievement_unlocked(title: String, desc: String)

# 成就定义：id 唯一，name/desc 展示用
const ACHIEVEMENTS = [
	{ "id": "first_win",         "name": "First Clear",     "desc": "Clear your first level" },
	{ "id": "three_star",        "name": "Perfectionist",   "desc": "Earn 3 stars on a level" },
	{ "id": "combo_master",      "name": "Combo Master",    "desc": "Reach a x3 combo" },
	{ "id": "campaign_complete", "name": "Champion",        "desc": "Complete every campaign level" },
	{ "id": "endless_5",         "name": "Survivor",        "desc": "Reach wave 5 in Endless" },
	{ "id": "endless_10",        "name": "Unstoppable",     "desc": "Reach wave 10 in Endless" },
	{ "id": "rank_gold",         "name": "Golden",          "desc": "Reach Gold rank" },
	{ "id": "score_10k",         "name": "High Roller",     "desc": "Accumulate 10,000 total score" },
]

# 段位从低到高，用于比较“达到 Gold 及以上”
const RANK_ORDER = ["Bronze", "Silver", "Gold", "Platinum", "Diamond", "Master", "King"]

func _unlocked_list() -> Array:
	# 存档里没有该字段时兜底为空数组
	if not SaveManager.data.has("achievements"):
		SaveManager.data["achievements"] = []
	return SaveManager.data["achievements"]

func _find(id: String) -> Dictionary:
	for a in ACHIEVEMENTS:
		if a["id"] == id:
			return a
	return {}

func is_unlocked(id: String) -> bool:
	return id in _unlocked_list()

# 返回 true 表示这次是“新解锁”，会发信号并存档
func unlock(id: String) -> bool:
	var a = _find(id)
	if a.is_empty():
		return false                 # 未知成就，忽略
	if is_unlocked(id):
		return false                 # 已解锁，不重复
	_unlocked_list().append(id)
	SaveManager.save_game()
	emit_signal("achievement_unlocked", a["name"], a["desc"])
	return true

func get_all() -> Array:
	return ACHIEVEMENTS

func unlocked_count() -> int:
	return _unlocked_list().size()

# ===== 事件入口（由 UI 在对应信号里调用）=====
func on_level_won(stars: int):
	unlock("first_win")
	if stars >= 3:
		unlock("three_star")

func on_campaign_complete():
	unlock("first_win")
	unlock("campaign_complete")

func on_combo(combo: int):
	if combo >= 3:
		unlock("combo_master")

func on_endless_wave(wave: int):
	if wave >= 5:
		unlock("endless_5")
	if wave >= 10:
		unlock("endless_10")

func on_score_changed():
	if int(SaveManager.data.get("total_score", 0)) >= 10000:
		unlock("score_10k")
	# 达到 Gold 及以上段位
	var cur = SaveManager.get_rank()
	if RANK_ORDER.find(cur) >= RANK_ORDER.find("Gold"):
		unlock("rank_gold")
