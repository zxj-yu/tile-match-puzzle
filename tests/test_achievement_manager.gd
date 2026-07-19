extends GutTest

# 快照并还原存档，避免测试污染真实进度
var _score
var _ach

func before_each():
	_score = SaveManager.data.get("total_score", 0)
	_ach = SaveManager.data["achievements"].duplicate()
	SaveManager.data["achievements"] = []   # 清空已解锁，保证测试互相隔离

func after_each():
	SaveManager.data["total_score"] = _score
	SaveManager.data["achievements"] = _ach
	SaveManager.save_game()

func test_unlock_returns_true_first_time_false_after():
	assert_true(AchievementManager.unlock("first_win"), "首次解锁应返回 true")
	assert_false(AchievementManager.unlock("first_win"), "重复解锁应返回 false")

func test_unlock_unknown_id_is_ignored():
	assert_false(AchievementManager.unlock("not_a_real_id"), "未知成就应返回 false")
	assert_eq(AchievementManager.unlocked_count(), 0, "未知成就不应写入")

func test_is_unlocked_reflects_state():
	assert_false(AchievementManager.is_unlocked("combo_master"))
	AchievementManager.unlock("combo_master")
	assert_true(AchievementManager.is_unlocked("combo_master"))

func test_unlock_persists_to_save():
	AchievementManager.unlock("three_star")
	assert_true("three_star" in SaveManager.data["achievements"], "解锁应写入存档")

func test_level_won_three_stars_unlocks_both():
	AchievementManager.on_level_won(3)
	assert_true(AchievementManager.is_unlocked("first_win"), "通关应解锁首胜")
	assert_true(AchievementManager.is_unlocked("three_star"), "三星应解锁完美主义")

func test_level_won_one_star_no_three_star():
	AchievementManager.on_level_won(1)
	assert_true(AchievementManager.is_unlocked("first_win"))
	assert_false(AchievementManager.is_unlocked("three_star"), "1星不应解锁三星成就")

func test_combo_threshold():
	AchievementManager.on_combo(2)
	assert_false(AchievementManager.is_unlocked("combo_master"), "x2 连击不解锁")
	AchievementManager.on_combo(3)
	assert_true(AchievementManager.is_unlocked("combo_master"), "x3 连击解锁")

func test_endless_wave_thresholds():
	AchievementManager.on_endless_wave(10)
	assert_true(AchievementManager.is_unlocked("endless_5"), "到第10波应同时解锁第5波成就")
	assert_true(AchievementManager.is_unlocked("endless_10"), "到第10波应解锁第10波成就")

func test_endless_wave_below_five():
	AchievementManager.on_endless_wave(4)
	assert_false(AchievementManager.is_unlocked("endless_5"), "第4波不应解锁")

func test_score_and_rank_achievements():
	SaveManager.data["total_score"] = 10000   # 达到 High Roller，且段位为 Gold
	AchievementManager.on_score_changed()
	assert_true(AchievementManager.is_unlocked("score_10k"), "满1万分应解锁 High Roller")
	assert_true(AchievementManager.is_unlocked("rank_gold"), "Gold 段位应解锁 Golden")

func test_rank_gold_not_unlocked_below_gold():
	SaveManager.data["total_score"] = 3000    # Silver
	AchievementManager.on_score_changed()
	assert_false(AchievementManager.is_unlocked("rank_gold"), "Silver 不应解锁 Gold 成就")
	assert_false(AchievementManager.is_unlocked("score_10k"), "3000分不应解锁 High Roller")
