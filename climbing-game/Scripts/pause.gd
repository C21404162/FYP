# PauseMenu.gd
extends Control

@onready var pause_panel = $pause_panel
@onready var options_panel = $options_panel
@onready var saveload_panel = $saveload_panel
@onready var game_manager = GameManager
@onready var fov_slider = $options_panel/VBoxContainer/HBoxContainer/FOVSlider

func _ready():
	#Hide the pause menu and options panel when the scene starts
	pause_panel.hide()
	options_panel.hide()
	saveload_panel.hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	#Load the saved FOV value 
	fov_slider.value = game_manager.fov
	fov_slider.connect("value_changed", Callable(self, "_on_fov_changed"))

func _on_fov_changed(value: float):
	#Update the FOV in GameManager
	game_manager.set_fov(value)

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
