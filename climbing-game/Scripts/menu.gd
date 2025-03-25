extends Control

@onready var options_panel = $options_panel
@onready var fov_slider = $options_panel/VBoxContainer/FOVSlider
@onready var fov_label = $options_panel/VBoxContainer/Label
@onready var sensitivity_slider = $options_panel/VBoxContainer/SENSSlider
@onready var sensitivity_label = $options_panel/VBoxContainer/Label2

#cam animation
@onready var animation_player = $camera_into_well
@onready var fade_color_rect = $CanvasLayer/ColorRect

#forest_sounds
@onready var forest_ambience = $forest_ambience

#hover noise
@export var hover_sounds: Array[AudioStream] = []
@onready var hover_sound_player = $HoverSoundPlayer

#cam
@onready var Camera: Camera3D =  $Menu_cam
var original_camera_position: Vector3

#gamemanager
@onready var game_manager = GameManager

#continue
@onready var ogham_label_continue: Label =$VBoxContainer/continue/ogham_label_continue
@onready var english_label_continue: Label =$VBoxContainer/continue/english_label_continue

#start
@onready var ogham_label_start: Label = $VBoxContainer/start/ogham_label_start
@onready var english_label_start: Label = $VBoxContainer/start/english_label_start

#options
@onready var ogham_label_options: Label = $VBoxContainer/options/ogham_label_options
@onready var english_label_options: Label = $VBoxContainer/options/english_label_options

#exit
@onready var ogham_label_exit: Label = $VBoxContainer/exit/ogham_label_exit
@onready var english_label_exit: Label = $VBoxContainer/exit/english_label_exit

func _on_speedrun_checkbox_toggled(button_pressed):
	# Just update the mode, no UI updates needed in menu
	GameManager.speedrun_mode = button_pressed

func _ready() -> void:
	
	if forest_ambience:
		forest_ambience.play()
		
	self.modulate = Color(1, 1, 1, 0)
	fade_color_rect.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(self, "modulate", Color(1, 1, 1, 1), 1.65)
	
	$options_panel/VBoxContainer/SpeedrunCheckbox.button_pressed = GameManager.speedrun_mode
	$options_panel/VBoxContainer/SpeedrunCheckbox.toggled.connect(_on_speedrun_checkbox_toggled)
	
	options_panel.hide()
	
	fov_slider.value = game_manager.fov
	fov_slider.connect("value_changed", Callable(self, "_on_fov_changed"))
	
	sensitivity_slider.value = game_manager.sensitivity
	sensitivity_slider.connect("value_changed", Callable(self, "_on_sensitivity_changed"))
	
	#fade_in.play("fade_in") 
	
	#Visiblity
	ogham_label_continue.modulate = Color(1, 1, 1, 1)  
	english_label_continue.modulate = Color(1, 1, 1, 0)  
	
	ogham_label_start.modulate = Color(1, 1, 1, 1)  
	english_label_start.modulate = Color(1, 1, 1, 0) 
	
	ogham_label_options.modulate = Color(1, 1, 1, 1)  
	english_label_options.modulate = Color(1, 1, 1, 0) 
	 
	ogham_label_exit.modulate = Color(1, 1, 1, 1)  
	english_label_exit.modulate = Color(1, 1, 1, 0)

	#Focus the first button
	#$VBoxContainer/start.grab_focus()

func _on_start_pressed() -> void:
	var shake_amount = 5.0
	create_tween().tween_property($VBoxContainer/start, "position:x", $VBoxContainer/start.position.x + shake_amount, 0.05).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property($VBoxContainer/start, "position:x", $VBoxContainer/start.position.x - shake_amount, 0.05).set_trans(Tween.TRANS_SINE).set_delay(0.05)
	create_tween().tween_property($VBoxContainer/start, "position:x", $VBoxContainer/start.position.x, 0.05).set_trans(Tween.TRANS_SINE).set_delay(0.1)
	await get_tree().create_timer(0.10).timeout

	if Camera:
		Camera.reset_camera_smoothly(0.8)  
		await get_tree().create_timer(0.8).timeout  	

	# Play the animation
	animation_player.play("camera_into_well")
	await animation_player.animation_finished

	# Change scene
	get_tree().change_scene_to_file("res://world.tscn")

func _on_exit_pressed() -> void:
	var shake_amount = 5.0
	create_tween().tween_property($VBoxContainer/exit, "position:x", $VBoxContainer/exit.position.x + shake_amount, 0.05).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property($VBoxContainer/exit, "position:x", $VBoxContainer/exit.position.x - shake_amount, 0.05).set_trans(Tween.TRANS_SINE).set_delay(0.05)
	create_tween().tween_property($VBoxContainer/exit, "position:x", $VBoxContainer/exit.position.x, 0.05).set_trans(Tween.TRANS_SINE).set_delay(0.1)
	await get_tree().create_timer(0.10).timeout
	get_tree().quit()

func _on_mouse_entered_start():
	if ogham_label_start and english_label_start:
		var shake_amount = 5.0
		create_tween().tween_property($VBoxContainer/start, "scale", Vector2(1.1, 1.1), 0.1)
		create_tween().tween_property(ogham_label_start, "modulate", Color(1, 1, 1, 0), 0.7)
		create_tween().tween_property(english_label_start, "modulate", Color(1, 1, 1, 1), 0.7)
		play_hover_sound()

func _on_mouse_entered_options():
	if ogham_label_options and english_label_options:
		create_tween().tween_property($VBoxContainer/options, "scale", Vector2(1.1, 1.1), 0.1)
		create_tween().tween_property(ogham_label_options, "modulate", Color(1, 1, 1, 0), 0.7)
		create_tween().tween_property(english_label_options, "modulate", Color(1, 1, 1, 1), 0.7)
		play_hover_sound()

func _on_mouse_entered_exit():
	if ogham_label_exit and english_label_exit:
		create_tween().tween_property($VBoxContainer/exit, "scale", Vector2(1.1, 1.1), 0.1)
		create_tween().tween_property(ogham_label_exit, "modulate", Color(1, 1, 1, 0), 0.7)
		create_tween().tween_property(english_label_exit, "modulate", Color(1, 1, 1, 1), 0.7)
		play_hover_sound()

func _on_mouse_entered_continue() -> void:
	if ogham_label_continue and english_label_continue:
		create_tween().tween_property($VBoxContainer/continue, "scale", Vector2(1.1, 1.1), 0.1)
		create_tween().tween_property(ogham_label_continue, "modulate", Color(1, 1, 1, 0), 0.7)
		create_tween().tween_property(english_label_continue, "modulate", Color(1, 1, 1, 1), 0.7)
		play_hover_sound()

func _on_continue_pressed() -> void:
	GameManager.speedrun_mode = false
	print("LOADING GAME (Speedrun disabled for continues)")
	print("LOADING GAME")
	game_manager.load_game_data()
	print("LOADED")
	get_tree().change_scene_to_file("res://world.tscn")
	
func play_hover_sound():
	hover_sound_player.volume_db = -20
	if hover_sound_player and hover_sounds.size() > 0:
		var random_index = randi() % hover_sounds.size()
		hover_sound_player.stream = hover_sounds[random_index]
		hover_sound_player.pitch_scale = randf_range(1.2, 2.5)
		hover_sound_player.play()

func _on_continue_mouse_exited() -> void:
	create_tween().tween_property($VBoxContainer/continue, "scale", Vector2(1, 1), 0.1)


func _on_start_mouse_exited() -> void:
	create_tween().tween_property($VBoxContainer/start, "scale", Vector2(1, 1), 0.1)


func _on_options_mouse_exited() -> void:
	create_tween().tween_property($VBoxContainer/options, "scale", Vector2(1, 1), 0.1)


func _on_exit_mouse_exited() -> void:
	create_tween().tween_property($VBoxContainer/exit, "scale", Vector2(1, 1), 0.1)


func _on_options_pressed() -> void:
	play_hover_sound()
	var shake_amount = 5.0
	create_tween().tween_property($VBoxContainer/options, "position:x", $VBoxContainer/options.position.x + shake_amount, 0.05).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property($VBoxContainer/options, "position:x", $VBoxContainer/options.position.x - shake_amount, 0.05).set_trans(Tween.TRANS_SINE).set_delay(0.05)
	create_tween().tween_property($VBoxContainer/options, "position:x", $VBoxContainer/options.position.x, 0.05).set_trans(Tween.TRANS_SINE).set_delay(0.1)
	await get_tree().create_timer(0.10).timeout
	
	options_panel.show()


func _on_back_pressed() -> void:
	options_panel.hide()

func _on_fov_slider_value_changed(value: float) -> void:
	game_manager.set_fov(value)
	fov_label.text = "Fov: %.0f" % fov_slider.value

func _on_sens_slider_value_changed(value: float) -> void:
	game_manager.set_sensitivity(value)
	sensitivity_label.text = "Sensitivity: %.3f" % sensitivity_slider.value
