extends Control

func _ready():
	# Hide the pause menu when the scene starts
	hide()
	# Ensure pause mode is set to process so the menu can work when the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func toggle_pause():
	# Ensure the SceneTree is available
	if not is_inside_tree():
		print("Pause menu is not part of the SceneTree!")
		return

	# Toggle visibility and pause state
	visible = !visible
	
	if visible:
		# Pause the game
		get_tree().paused = true
		# Show the mouse cursor
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		# Unpause the game
		get_tree().paused = false
		# Hide the mouse cursor (optional, depending on your game)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Resume button handler
func _on_resume_button_pressed():
	toggle_pause()

# Quit to main menu
func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")
	
