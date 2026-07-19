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
