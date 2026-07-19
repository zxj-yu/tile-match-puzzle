extends GutTest

# 关卡数据完整性测试：直接读 levels.json
var levels

func before_all():
	var f = FileAccess.open("res://levels.json", FileAccess.READ)
	var json = JSON.new()
	json.parse(f.get_as_text())
	f.close()
	levels = json.data["levels"]

func test_has_thirty_levels():
	assert_eq(levels.size(), 30, "应有 30 个关卡")

func test_every_level_has_required_fields():
	for L in levels:
		for key in ["name", "types", "time_limit", "slot_count", "star_times", "layers"]:
			assert_true(L.has(key), "关卡应包含字段 " + key)
		assert_eq(L["star_times"].size(), 3, "每关应有三档星级阈值")

func test_star_times_are_ascending():
	# 3星阈值 <= 2星阈值 <= 1星阈值(=time_limit)
	for L in levels:
		var st = L["star_times"]
		assert_true(float(st[0]) <= float(st[1]) and float(st[1]) <= float(st[2]),
			str(L["name"]) + " 的星级阈值应从严到松递增")

func test_types_within_texture_range():
	# Item.gd 只有 18 种贴图（0..17），types 不能超过 18
	for L in levels:
		assert_true(int(L["types"]) >= 1 and int(L["types"]) <= 18,
			str(L["name"]) + " 的花色数应在 1..18 之间")
