extends Control

@onready var pause_panel = $pause_panel
@onready var options_panel = $options_panel
@onready var saveload_panel = $saveload_panel

# Reference to the player character (you'll need to set this)
@export var player: Node3D

func _ready():
	# Hide the pause menu and options panel when the scene starts
	pause_panel.hide()
	options_panel.hide()
	saveload_panel.hide()
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

# Save game function
func _on_save_pressed():
	# Create a new SaveGame resource
	var save_game = SaveGame.new()
	
	# Populate save data
	if player:
		save_game.player_position = player.global_position
		save_game.player_rotation = player.rotation_degrees
	
	# Optional: Add more save data like health, inventory, etc.
	# save_game.health = player.health
	# save_game.inventory = player.inventory
	
	# Save the game
	save_game.write_savegame()
	print("Game saved successfully!")

# Load game function
func _on_load_pressed():
	# Attempt to load the saved game
	var loaded_save = SaveGame.load_savegame()
	
	if loaded_save:
		# Restore player position and rotation
		if player:
			player.global_position = loaded_save.player_position
			player.rotation_degrees = loaded_save.player_rotation
		
		# Optional: Restore other game state
		# player.health = loaded_save.health
		# player.inventory = loaded_save.inventory
		
		# Unpause the game after loading
		get_tree().paused = false
		visible = false
		print("Game loaded successfully!")
	else:
		print("No save game found!")

# Existing pause menu functions remain the same
func _on_resume_pressed():
	toggle_pause()

func _on_exit_pressed() -> void:
	# Unpause the game before changing scenes
	get_tree().paused = false
	# Change to the main menu scene
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
