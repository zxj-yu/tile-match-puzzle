extends GutTest

func test_rank_at_zero_score_is_bronze():
	SaveManager.data["total_score"] = 0
	assert_eq(SaveManager.get_rank(), "Bronze", "0分应为Bronze段位")

func test_rank_exact_threshold():
	# 恰好等于门槛分数，应该算进入该段位
	SaveManager.data["total_score"] = 3000
	assert_eq(SaveManager.get_rank(), "Silver", "恰好3000分应为Silver")

func test_rank_just_below_threshold():
	SaveManager.data["total_score"] = 2999
	assert_eq(SaveManager.get_rank(), "Bronze", "2999分应仍为Bronze")

func test_rank_max_tier():
	SaveManager.data["total_score"] = 999999
	assert_eq(SaveManager.get_rank(), "King", "超高分应为最高段位King")

func test_level_stars_never_decrease():
	SaveManager.data["level_stars"] = {}
	SaveManager.record_level_clear(0, 3)
	SaveManager.record_level_clear(0, 1)  # 后面打得差，星级不该下降
	assert_eq(SaveManager.get_level_stars(0), 3, "星级记录应保留历史最高分")

# ===== 每日挑战成绩 =====
func test_daily_records_and_keeps_best_time():
	SaveManager.data["daily_date"] = ""       # 强制视为新的一天
	SaveManager.data["daily_best_time"] = 0.0
	SaveManager.record_daily(50.0)
	assert_almost_eq(SaveManager.get_daily_best(), 50.0, 0.01, "首次通关记录 50 秒")
	SaveManager.record_daily(70.0)            # 更慢
	assert_almost_eq(SaveManager.get_daily_best(), 50.0, 0.01, "更差成绩不应覆盖")
	SaveManager.record_daily(30.0)            # 更快
	assert_almost_eq(SaveManager.get_daily_best(), 30.0, 0.01, "更好成绩应更新")

func test_daily_done_flag():
	SaveManager.data["daily_date"] = ""
	SaveManager.data["daily_best_time"] = 0.0
	assert_false(SaveManager.daily_done_today(), "还没通关时应为 false")
	SaveManager.record_daily(42.0)
	assert_true(SaveManager.daily_done_today(), "通关后当天应为 true")

# ===== Roguelite 记录 =====
func test_rogue_records_best_stage_and_score_independently():
	SaveManager.data["rogue_best_stage"] = 0
	SaveManager.data["rogue_best_score"] = 0
	SaveManager.record_rogue(3, 500)
	assert_eq(int(SaveManager.data["rogue_best_stage"]), 3, "首次记录层数3")
	assert_eq(int(SaveManager.data["rogue_best_score"]), 500, "首次记录分数500")
	SaveManager.record_rogue(2, 999)   # 层数更低、分数更高
	assert_eq(int(SaveManager.data["rogue_best_stage"]), 3, "更低层数不应覆盖最高层")
	assert_eq(int(SaveManager.data["rogue_best_score"]), 999, "更高分应更新")
	SaveManager.record_rogue(5, 100)   # 层数更高、分数更低
	assert_eq(int(SaveManager.data["rogue_best_stage"]), 5, "更高层应更新")
	assert_eq(int(SaveManager.data["rogue_best_score"]), 999, "更低分不应覆盖最高分")

# ===== 关卡地图：累计星数 + 门槛解锁 =====
func test_total_stars_sums_level_stars():
	SaveManager.data["level_stars"] = { "0": 3, "1": 2, "2": 1 }
	assert_eq(SaveManager.total_stars(), 6, "累计星数应为各关之和")

func test_star_gate_thresholds():
	assert_eq(SaveManager.star_gate_for(0), 0, "第一段(1-5关)免门槛")
	assert_eq(SaveManager.star_gate_for(5), 6, "第二段(第6关)门槛 6 星")
	assert_eq(SaveManager.star_gate_for(10), 15, "第三段门槛 15 星")

func test_is_level_unlocked_respects_star_gate():
	SaveManager.data["unlocked_level"] = 9        # 顺序上第6-10关都到位
	SaveManager.data["level_stars"] = {}          # 0 星
	assert_false(SaveManager.is_level_unlocked(5), "第6关需6星，0星时应锁住")
	SaveManager.data["level_stars"] = { "0": 3, "1": 3 }   # 6 星
	assert_true(SaveManager.is_level_unlocked(5), "凑够6星后第6关应解锁")

func test_is_level_unlocked_respects_sequence():
	SaveManager.data["unlocked_level"] = 2        # 顺序只到第3关
	SaveManager.data["level_stars"] = { "0": 3, "1": 3, "2": 3, "3": 3 }  # 12星够门槛
	assert_false(SaveManager.is_level_unlocked(5), "顺序没到，即使星够也应锁住")
