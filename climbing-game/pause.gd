extends Control

@onready var pause_panel = $pause_panel
@onready var options_panel = $options_panel

func _ready():
	# Hide the pause menu and options panel when the scene starts
	pause_panel.hide()
	options_panel.hide()
	# Ensure pause mode is set to process so the menu can work when the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func toggle_pause():
	# Toggle visibility and pause state
	visible = !visible
	
	if visible:
		# Pause the game
		get_tree().paused = true
		# Show the mouse cursor
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		# Ensure the options panel is hidden when pausing
		options_panel.hide()
		pause_panel.show()
	else:
		# Unpause the game
		get_tree().paused = false
		# Hide the mouse cursor (optional, depending on your game)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Resume button handler
func _on_resume_pressed():
	toggle_pause()

# Quit to main menu
func _on_exit_pressed() -> void:
	# Unpause the game before changing scenes
	get_tree().paused = false
	# Change to the main menu scene
	get_tree().change_scene_to_file("res://menu.tscn")
	
func _on_options_pressed():
	pause_panel.hide()
	options_panel.show()

func _on_back_button_pressed():
	options_panel.hide()
	pause_panel.show()
