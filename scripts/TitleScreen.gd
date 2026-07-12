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
		subtitle_label.text = "Begin your matching journey"
	else:
		subtitle_label.text = "Rank: " + rank + "    Level " + str(int(unlocked) + 1) + " unlocked    Endless best: Wave " + str(int(best_wave))

func show_screen():
	visible = true
	refresh()

func hide_screen():
	visible = false
