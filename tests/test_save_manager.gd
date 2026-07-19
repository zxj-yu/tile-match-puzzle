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
