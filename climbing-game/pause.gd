# PauseMenu.gd
extends Control

@onready var pause_panel = $pause_panel
@onready var options_panel = $options_panel
@onready var saveload_panel = $saveload_panel
@onready var game_manager = GameManager

# Reference to the FOV slider in the options panel
@onready var fov_slider = $options_panel/VBoxContainer/HBoxContainer/FOVSlider

func _ready():
	# Debug: Check if game_manager is null
	if game_manager == null:
		print("ERROR: game_manager is null! Ensure it's properly initialized.")
	else:
		print("game_manager is properly initialized.")
	
	# Debug: Check if fov_slider is null
	if fov_slider == null:
		print("ERROR: fov_slider is null! Check the node path.")
	else:
		print("fov_slider is properly initialized.")
	
	# Load the saved FOV value (if any)
	fov_slider.value = game_manager.fov
	
	# Connect the FOV slider's value_changed signal
	fov_slider.connect("value_changed", Callable(self, "_on_fov_changed"))

func _on_fov_changed(value: float):
	# Update the FOV in GameManager
	game_manager.set_fov(value)
	
	# Save the game data to persist the FOV setting
	game_manager.save_game_data()

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
