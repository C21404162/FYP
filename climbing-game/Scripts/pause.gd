# PauseMenu.gd
extends Control

@onready var pause_panel = $pause_panel
@onready var options_panel = $options_panel
@onready var saveload_panel = $saveload_panel
@onready var game_manager = GameManager
@onready var fov_slider = $options_panel/VBoxContainer/FOVSlider
@onready var fov_label = $options_panel/VBoxContainer/Label
@onready var sensitivity_slider = $options_panel/VBoxContainer/HSlider
@onready var sensitivity_label = $options_panel/VBoxContainer/Label2


func _ready():
	
	#hides
	pause_panel.hide()
	options_panel.hide()
	saveload_panel.hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	#loadfov
	fov_slider.value = game_manager.fov
	fov_slider.connect("value_changed", Callable(self, "_on_fov_changed"))
	fov_label.text = "Fov: %.0f" % fov_slider.value
	
	#loadsens
	sensitivity_label.text = "Sensitivity: %.3f" % sensitivity_slider.value
	sensitivity_slider.value = game_manager.sensitivity
	sensitivity_slider.connect("value_changed", Callable(self, "_on_sensitivity_changed"))

func _on_fov_changed(value: float):
	game_manager.set_fov(value)
	fov_label.text = "Fov: %.0f" % value

func toggle_pause():
	visible = !visible
	if visible:
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		options_panel.hide()
		pause_panel.show()
	else:
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func onsave_pressed():
	game_manager.save_game_data()

func onload_pressed():
	game_manager.load_game_data()

func _on_resume_pressed():
	toggle_pause()
	
func _on_exit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu.tscn")

func _on_options_pressed():
	pause_panel.hide()
	saveload_panel.hide()
	options_panel.show()

func _on_back_pressed():
	options_panel.hide()
	saveload_panel.hide()
	pause_panel.show()

func _on_saveload_pressed() -> void:
	options_panel.hide()
	saveload_panel.show()
	pause_panel.hide()
	
func _on_h_slider_value_changed(value: float) -> void:
	game_manager.set_sensitivity(value)
	sensitivity_label.text = "Sensitivity: %.3f" % value
