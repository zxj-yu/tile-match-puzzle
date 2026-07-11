extends CanvasLayer

@onready var grid_manager = $"../GridManager"
@onready var message_label = $MessageLabel
@onready var score_label = $ScoreLabel
@onready var time_label = $TimeLabel
@onready var add_button = $AddButton
@onready var result_panel = $ResultPanel
@onready var result_label = $ResultPanel/ResultLabel
@onready var result_button = $ResultPanel/ResultButton
@onready var start_menu = $StartMenu
@onready var level_select = $"../LevelSelect"
@onready var title_screen = $"../TitleScreen"
@onready var pause_button = $PauseButton
@onready var pause_panel = $PausePanel
@onready var skill_bar = $SkillBar
@onready var slot_skill_button = $SkillBar/SlotSkillButton
@onready var time_skill_button = $SkillBar/TimeSkillButton
@onready var shuffle_skill_button = $SkillBar/ShuffleSkillButton

var button_mode = "retry"

func _ready():
	add_button.pressed.connect(_on_add_button_pressed)
	result_button.pressed.connect(_on_result_button_pressed)

	title_screen.start_pressed.connect(_on_title_start)
	title_screen.endless_pressed.connect(_on_title_endless)

	level_select.level_chosen.connect(_on_level_chosen)
	$"../LevelSelect/Panel/BackButton".pressed.connect(_on_level_select_back)

	# 暂停
	pause_button.pressed.connect(_on_pause_pressed)
	$PausePanel/ResumeButton.pressed.connect(_on_resume_pressed)
	$PausePanel/RetryButton.pressed.connect(_on_pause_retry)
	$PausePanel/HomeButton.pressed.connect(_on_pause_home)

	# 道具
	slot_skill_button.pressed.connect(func(): grid_manager.use_skill_slot())
	time_skill_button.pressed.connect(func(): grid_manager.use_skill_time())
	shuffle_skill_button.pressed.connect(func(): grid_manager.use_skill_shuffle())

	grid_manager.progress_changed.connect(_on_progress_changed)
	grid_manager.level_changed.connect(_on_level_changed)
	grid_manager.level_won_stars.connect(_on_level_won_stars)
	grid_manager.all_levels_complete.connect(_on_all_complete)
	grid_manager.game_lost.connect(_on_game_lost)
	grid_manager.wave_changed.connect(_on_wave_changed)
	grid_manager.time_updated.connect(_on_time_updated)
	grid_manager.score_updated.connect(_on_score_updated)
	grid_manager.skills_updated.connect(_on_skills_updated)

	result_panel.visible = false
	start_menu.visible = false
	pause_panel.visible = false
	pause_button.visible = false
	skill_bar.visible = false
	level_select.hide_menu()
	title_screen.show_screen()
	time_label.text = ""

# ===== 首页 =====
func _on_title_start():
	title_screen.hide_screen()
	pause_button.visible = false
	skill_bar.visible = false
	level_select.build(grid_manager.campaign_levels.size())
	level_select.show_menu()

func _on_title_endless():
	title_screen.hide_screen()
	pause_button.visible = true
	skill_bar.visible = true
	grid_manager.start_endless()

# ===== 关卡选择 =====
func _on_level_chosen(index: int):
	level_select.hide_menu()
	pause_button.visible = true
	skill_bar.visible = true
	grid_manager.start_level(index)

func _on_level_select_back():
	level_select.hide_menu()
	pause_button.visible = false
	skill_bar.visible = false
	title_screen.show_screen()

func _return_to_level_select():
	pause_button.visible = false
	skill_bar.visible = false
	level_select.build(grid_manager.campaign_levels.size())
	level_select.show_menu()

# ===== 暂停 =====
func _on_pause_pressed():
	grid_manager.pause_game()
	pause_panel.visible = true

func _on_resume_pressed():
	pause_panel.visible = false
	grid_manager.resume_game()

func _on_pause_retry():
	pause_panel.visible = false
	grid_manager.retry_level()

func _on_pause_home():
	pause_panel.visible = false
	pause_button.visible = false
	skill_bar.visible = false
	grid_manager.quit_to_title()
	title_screen.show_screen()

# ===== 道具显示 =====
func _on_skills_updated(slot: int, time: int, shuffle: int):
	slot_skill_button.text = "➕收纳格 x" + str(slot)
	time_skill_button.text = "⏱+5秒 x" + str(time)
	shuffle_skill_button.text = "🔀打乱 x" + str(shuffle)
	slot_skill_button.disabled = slot <= 0
	time_skill_button.disabled = time <= 0
	shuffle_skill_button.disabled = shuffle <= 0

# ===== 游戏内按钮 =====
func _on_add_button_pressed():
	grid_manager.retry_level()

func _on_result_button_pressed():
	result_panel.visible = false
	match button_mode:
		"retry":
			grid_manager.retry_level()
		"next":
			_return_to_level_select()
		"restart_all":
			_return_to_level_select()

# ===== 关卡事件 =====
func _on_level_changed(level_index: int):
	result_panel.visible = false
	add_button.text = "重试本关"
	message_label.text = "点击最上层方块，凑齐3个相同的消除"

func _on_progress_changed(remaining: int):
	if grid_manager.mode == grid_manager.Mode.ENDLESS:
		score_label.text = "剩余：" + str(remaining)
	else:
		score_label.text = "第" + str(grid_manager.current_level + 1) + "关 | 剩余：" + str(remaining)

func _on_time_updated(seconds_left: float):
	var s = int(ceil(seconds_left))
	time_label.text = "⏱ " + str(s) + "s"
	if s <= 10:
		time_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	else:
		time_label.add_theme_color_override("font_color", Color(0.35, 0.28, 0.22))

func _on_score_updated(current: int, combo: int):
	var rank = SaveManager.get_rank()
	var combo_str = ""
	if combo >= 2:
		var mult = min(1.0 + (combo - 1) * 0.5, 3.0)
		combo_str = "  连击x" + str(combo) + " (×" + str(mult) + ")"
	message_label.text = "本局 " + str(current) + " | 段位:" + rank + combo_str

func _on_wave_changed(wave: int):
	time_label.text = ""
	score_label.text = "无尽模式 | 第 " + str(wave) + " 波"

# ===== 结算 =====
func _on_level_won_stars(level_index: int, stars: int, time_used: float):
	button_mode = "next"
	var star_str = "⭐".repeat(stars) + "☆".repeat(3 - stars)
	result_label.text = star_str + "\n用时 " + str(int(time_used)) + " 秒\n段位:" + SaveManager.get_rank()
	result_button.text = "返回关卡选择"
	pause_button.visible = false
	skill_bar.visible = false
	_show_result()

func _on_all_complete():
	button_mode = "restart_all"
	result_label.text = "🏆 全部通关！\n段位:" + SaveManager.get_rank()
	result_button.text = "返回关卡选择"
	pause_button.visible = false
	skill_bar.visible = false
	_show_result()

func _on_game_lost():
	button_mode = "retry"
	if grid_manager.mode == grid_manager.Mode.ENDLESS:
		result_label.text = "💀 撑到第 " + str(grid_manager.endless_wave + 1) + " 波！"
	else:
		result_label.text = "💀 时间到 / 收集槽满了！"
	result_button.text = "再来一次"
	_show_result()

func _show_result():
	result_panel.visible = true
	result_panel.pivot_offset = result_panel.size / 2
	result_panel.scale = Vector2(0.7, 0.7)
	var tw = create_tween()
	tw.tween_property(result_panel, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
