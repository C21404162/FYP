extends Node3D

@onready var ambience = $ambience
@onready var fade_in = $Fade_interact/fade_in  
@onready var left_hand = $Player/lefthand
@onready var right_hand = $Player/righthand
@onready var speedrun_timer_label = $SpeedrunTimer

func _process(delta):
	# Only update time if active
	if GameManager.speedrun_active:
		GameManager.speedrun_time += delta
		speedrun_timer_label.text = GameManager.get_formatted_time()

func update_speedrun_ui(visible: bool):
	speedrun_timer_label.visible = visible && GameManager.speedrun_mode
	if visible:
		speedrun_timer_label.text = GameManager.get_formatted_time()

func _ready() -> void:
	update_speedrun_ui(GameManager.speedrun_mode)
	fade_in.play("fade_in")
	ambience.play()
	ambience.volume_db = -20
	speedrun_timer_label.visible = GameManager.speedrun_mode
	if GameManager.speedrun_mode:
		GameManager.start_speedrun()
	#tween.interpolate_property(ambient_sound, "volume_db", -80, 0, 2.0)  # Fade in
	#tween.start()
