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
# 撤销按钮在代码里动态创建并加入 SkillBar（HBoxContainer 会自动排布）
var undo_skill_button: Button
# 设置菜单（代码构建的覆盖层）
var settings_menu
# 成就查看界面 + 解锁提示浮层
var achievements_menu
var _toast_panel: Panel
var _toast_title: Label
var _toast_desc: Label

var button_mode = "retry"

func _ready():
	add_button.pressed.connect(_on_add_button_pressed)
	result_button.pressed.connect(_on_result_button_pressed)
	title_screen.start_pressed.connect(_on_title_start)
	title_screen.endless_pressed.connect(_on_title_endless)
	level_select.level_chosen.connect(_on_level_chosen)
	$"../LevelSelect/Panel/BackButton".pressed.connect(_on_level_select_back)
	# Pause
	pause_button.pressed.connect(_on_pause_pressed)
	$PausePanel/ResumeButton.pressed.connect(_on_resume_pressed)
	$PausePanel/RetryButton.pressed.connect(_on_pause_retry)
	$PausePanel/HomeButton.pressed.connect(_on_pause_home)
	# Power-ups
	slot_skill_button.pressed.connect(func(): grid_manager.use_skill_slot())
	time_skill_button.pressed.connect(func(): grid_manager.use_skill_time())
	shuffle_skill_button.pressed.connect(func(): grid_manager.use_skill_shuffle())
	# 动态创建撤销按钮，加入 SkillBar 末尾
	undo_skill_button = Button.new()
	skill_bar.add_child(undo_skill_button)
	undo_skill_button.pressed.connect(func(): grid_manager.use_skill_undo())

	# 设置菜单覆盖层 + 两个入口按钮（标题屏、暂停面板）
	settings_menu = preload("res://scripts/SettingsMenu.gd").new()
	add_child(settings_menu)

	# 成就查看界面
	achievements_menu = preload("res://scripts/AchievementsMenu.gd").new()
	add_child(achievements_menu)
	# 成就解锁提示浮层
	_build_toast()
	AchievementManager.achievement_unlocked.connect(_show_achievement_toast)

	# 标题屏入口按钮：每日挑战 / 设置 / 成就（上下堆叠）
	var title_daily_btn = Button.new()
	title_daily_btn.text = "📅 Daily Challenge"
	title_daily_btn.position = Vector2(426, 566)
	title_daily_btn.size = Vector2(300, 46)
	$"../TitleScreen/Panel".add_child(title_daily_btn)
	ButtonStyler.style(title_daily_btn, Color(0.55, 0.8, 0.5), 20)
	title_daily_btn.pressed.connect(_on_title_daily)

	var title_settings_btn = Button.new()
	title_settings_btn.text = "⚙ Settings"
	title_settings_btn.position = Vector2(426, 620)
	title_settings_btn.size = Vector2(300, 46)
	$"../TitleScreen/Panel".add_child(title_settings_btn)
	ButtonStyler.style(title_settings_btn, Color(0.6, 0.62, 0.72), 20)
	title_settings_btn.pressed.connect(_open_settings)

	var title_ach_btn = Button.new()
	title_ach_btn.text = "🏆 Achievements"
	title_ach_btn.position = Vector2(426, 674)
	title_ach_btn.size = Vector2(300, 46)
	$"../TitleScreen/Panel".add_child(title_ach_btn)
	ButtonStyler.style(title_ach_btn, Color(0.95, 0.75, 0.35), 20)
	title_ach_btn.pressed.connect(_open_achievements)

	# 暂停面板的齿轮入口
	var pause_settings_btn = Button.new()
	pause_settings_btn.text = "⚙"
	pause_settings_btn.position = Vector2(244, 16)
	pause_settings_btn.size = Vector2(44, 44)
	pause_panel.add_child(pause_settings_btn)
	ButtonStyler.style(pause_settings_btn, Color(0.6, 0.62, 0.72), 20)
	pause_settings_btn.pressed.connect(_open_settings)

	grid_manager.progress_changed.connect(_on_progress_changed)
	grid_manager.level_changed.connect(_on_level_changed)
	grid_manager.level_won_stars.connect(_on_level_won_stars)
	grid_manager.all_levels_complete.connect(_on_all_complete)
	grid_manager.game_lost.connect(_on_game_lost)
	grid_manager.wave_changed.connect(_on_wave_changed)
	grid_manager.time_updated.connect(_on_time_updated)
	grid_manager.score_updated.connect(_on_score_updated)
	grid_manager.skills_updated.connect(_on_skills_updated)
	grid_manager.daily_won.connect(_on_daily_won)

	result_panel.visible = false
	start_menu.visible = false
	pause_panel.visible = false
	pause_button.visible = false
	skill_bar.visible = false
	level_select.hide_menu()
	title_screen.show_screen()
	time_label.text = ""
	# Layout & candy-button styling
	_setup_ui_layout()
	# Background music
	SoundManager.play_bgm()

func _setup_ui_layout():
	# ===== Layout =====
	pause_button.position = Vector2(1000, 130)
	pause_button.size = Vector2(120, 52)
	add_button.position = Vector2(1000, 195)
	add_button.size = Vector2(120, 52)
	skill_bar.position = Vector2(60, 706)
	skill_bar.size = Vector2(620, 56)

	# ===== Candy-style buttons =====
	ButtonStyler.style(pause_button, Color(1.0, 0.62, 0.35), 20)
	ButtonStyler.style(add_button, Color(1.0, 0.62, 0.35), 20)
	ButtonStyler.style(slot_skill_button, Color(0.45, 0.72, 0.95), 18)
	ButtonStyler.style(time_skill_button, Color(0.55, 0.8, 0.5), 18)
	ButtonStyler.style(shuffle_skill_button, Color(0.85, 0.55, 0.8), 18)
	ButtonStyler.style(undo_skill_button, Color(0.95, 0.75, 0.35), 18)
	ButtonStyler.style(result_button, Color(1.0, 0.62, 0.35), 22)
	ButtonStyler.style($PausePanel/ResumeButton, Color(0.55, 0.8, 0.5), 20)
	ButtonStyler.style($PausePanel/RetryButton, Color(1.0, 0.62, 0.35), 20)
	ButtonStyler.style($PausePanel/HomeButton, Color(0.85, 0.55, 0.8), 20)
	ButtonStyler.style($"../TitleScreen/Panel/StartButton", Color(1.0, 0.62, 0.35), 28)
	ButtonStyler.style($"../TitleScreen/Panel/EndlessButton", Color(0.45, 0.72, 0.95), 22)

# ===== Title screen =====
func _on_title_start():
	SoundManager.play("button")
	title_screen.hide_screen()
	pause_button.visible = false
	skill_bar.visible = false
	level_select.build(grid_manager.campaign_levels.size())
	level_select.show_menu()

func _on_title_endless():
	SoundManager.play("button")
	title_screen.hide_screen()
	pause_button.visible = true
	skill_bar.visible = true
	grid_manager.start_endless()

func _on_title_daily():
	SoundManager.play("button")
	title_screen.hide_screen()
	pause_button.visible = true
	skill_bar.visible = true
	grid_manager.start_daily()

# ===== Level select =====
func _on_level_chosen(index: int):
	SoundManager.play("button")
	level_select.hide_menu()
	pause_button.visible = true
	skill_bar.visible = true
	grid_manager.start_level(index)

func _on_level_select_back():
	SoundManager.play("button")
	level_select.hide_menu()
	pause_button.visible = false
	skill_bar.visible = false
	title_screen.show_screen()

func _return_to_level_select():
	pause_button.visible = false
	skill_bar.visible = false
	level_select.build(grid_manager.campaign_levels.size())
	level_select.show_menu()

# ===== Pause =====
func _on_pause_pressed():
	SoundManager.play("button")
	grid_manager.pause_game()
	pause_panel.visible = true

func _on_resume_pressed():
	SoundManager.play("button")
	pause_panel.visible = false
	grid_manager.resume_game()

func _on_pause_retry():
	SoundManager.play("button")
	pause_panel.visible = false
	grid_manager.retry_level()

func _on_pause_home():
	SoundManager.play("button")
	pause_panel.visible = false
	pause_button.visible = false
	skill_bar.visible = false
	grid_manager.quit_to_title()
	title_screen.show_screen()

# ===== Power-up display =====
func _on_skills_updated(slot: int, time: int, shuffle: int, undo: int):
	slot_skill_button.text = "➕Slot x" + str(slot)
	time_skill_button.text = "⏱+5s x" + str(time)
	shuffle_skill_button.text = "🔀Shuffle x" + str(shuffle)
	undo_skill_button.text = "↩Undo x" + str(undo)
	slot_skill_button.disabled = slot <= 0
	time_skill_button.disabled = time <= 0
	shuffle_skill_button.disabled = shuffle <= 0
	undo_skill_button.disabled = undo <= 0

# ===== In-game buttons =====
func _open_settings():
	SoundManager.play("button")
	settings_menu.open()

func _open_achievements():
	SoundManager.play("button")
	achievements_menu.open()

# ===== 成就解锁提示浮层 =====
func _build_toast():
	_toast_panel = Panel.new()
	_toast_panel.size = Vector2(420, 84)
	_toast_panel.position = Vector2(365, -100)   # 初始藏在屏幕上方
	_toast_panel.z_index = 200
	add_child(_toast_panel)

	var icon = Label.new()
	icon.text = "🏆"
	icon.add_theme_font_size_override("font_size", 40)
	icon.position = Vector2(16, 20)
	_toast_panel.add_child(icon)

	_toast_title = Label.new()
	_toast_title.add_theme_font_size_override("font_size", 24)
	_toast_title.position = Vector2(78, 12)
	_toast_panel.add_child(_toast_title)

	_toast_desc = Label.new()
	_toast_desc.add_theme_font_size_override("font_size", 18)
	_toast_desc.position = Vector2(78, 46)
	_toast_desc.modulate = Color(0.9, 0.9, 0.92)
	_toast_panel.add_child(_toast_desc)

	_toast_panel.visible = false

func _show_achievement_toast(title: String, desc: String):
	_toast_title.text = "Achievement: " + title
	_toast_desc.text = desc
	_toast_panel.visible = true
	_toast_panel.position.y = -100
	SoundManager.play("win")
	var tw = create_tween()
	tw.tween_property(_toast_panel, "position:y", 24, 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.4)
	tw.tween_property(_toast_panel, "position:y", -100, 0.35)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): _toast_panel.visible = false)

func _on_add_button_pressed():
	SoundManager.play("button")
	grid_manager.retry_level()

func _on_result_button_pressed():
	SoundManager.play("button")
	result_panel.visible = false
	match button_mode:
		"retry":
			grid_manager.retry_level()
		"next":
			_return_to_level_select()
		"restart_all":
			_return_to_level_select()
		"daily_done":
			pause_button.visible = false
			skill_bar.visible = false
			grid_manager.quit_to_title()
			title_screen.show_screen()

# ===== Level events =====
func _on_level_changed(level_index: int):
	result_panel.visible = false
	add_button.text = "Retry"
	message_label.text = "Tap uncovered tiles — match 3 to clear!"

func _on_progress_changed(remaining: int):
	if grid_manager.mode == grid_manager.Mode.ENDLESS:
		score_label.text = "Left: " + str(remaining)
	elif grid_manager.mode == grid_manager.Mode.DAILY:
		score_label.text = "Daily | Left: " + str(remaining)
	else:
		score_label.text = "Level " + str(grid_manager.current_level + 1) + " | Left: " + str(remaining)

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
		combo_str = "  Combo x" + str(combo) + " (×" + str(mult) + ")"
	message_label.text = "Score " + str(current) + " | Rank: " + rank + combo_str
	# 成就：连击、总分/段位
	AchievementManager.on_combo(combo)
	AchievementManager.on_score_changed()

func _on_wave_changed(wave: int):
	time_label.text = ""
	score_label.text = "Endless | Wave " + str(wave)
	AchievementManager.on_endless_wave(wave)  # 成就：无尽波数

# ===== Results =====
func _on_level_won_stars(level_index: int, stars: int, time_used: float):
	button_mode = "next"
	var star_str = "⭐".repeat(stars) + "☆".repeat(3 - stars)
	result_label.text = star_str + "\nTime: " + str(int(time_used)) + "s\nRank: " + SaveManager.get_rank()
	result_button.text = "Level Select"
	pause_button.visible = false
	skill_bar.visible = false
	# 成就：首胜 / 三星 / 段位
	AchievementManager.on_level_won(stars)
	AchievementManager.on_score_changed()
	_show_result()

func _on_daily_won(time_used: float):
	button_mode = "daily_done"
	var best = SaveManager.get_daily_best()
	result_label.text = "Daily cleared!\nTime: %ds\nBest today: %ds" % [int(time_used), int(best)]
	result_button.text = "Back to Title"
	pause_button.visible = false
	skill_bar.visible = false
	_show_result()

func _on_all_complete():
	button_mode = "restart_all"
	result_label.text = "All levels complete!\nRank: " + SaveManager.get_rank()
	result_button.text = "Level Select"
	pause_button.visible = false
	skill_bar.visible = false
	# 成就：通关全部关卡
	AchievementManager.on_campaign_complete()
	AchievementManager.on_score_changed()
	_show_result()

func _on_game_lost():
	button_mode = "retry"
	if grid_manager.mode == grid_manager.Mode.ENDLESS:
		result_label.text = "Reached Wave " + str(grid_manager.endless_wave + 1) + "!"
	else:
		result_label.text = "Time's up / Tray full!"
	result_button.text = "Try Again"
	_show_result()

func _show_result():
	result_panel.visible = true
	result_panel.pivot_offset = result_panel.size / 2
	result_panel.scale = Vector2(0.7, 0.7)
	var tw = create_tween()
	tw.tween_property(result_panel, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
