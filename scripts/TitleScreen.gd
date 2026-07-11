extends CanvasLayer

signal start_pressed
signal endless_pressed

@onready var subtitle_label = $Panel/SubtitleLabel

func _ready():
	$Panel/StartButton.pressed.connect(func(): emit_signal("start_pressed"))
	$Panel/EndlessButton.pressed.connect(func(): emit_signal("endless_pressed"))

func refresh():
	if subtitle_label == null:
		subtitle_label = $Panel/SubtitleLabel
	if subtitle_label == null:
		return
	var rank = SaveManager.get_rank()
	var unlocked = SaveManager.data["unlocked_level"]
	var best_wave = SaveManager.data["endless_best"]
	if unlocked == 0 and SaveManager.data["total_score"] == 0:
		subtitle_label.text = "开始你的消除之旅"
	else:
		subtitle_label.text = "段位：" + rank + "    已解锁 " + str(int(unlocked) + 1) + " 关    无尽最高 " + str(int(best_wave)) + " 波"

func show_screen():
	visible = true
	refresh()

func hide_screen():
	visible = false
