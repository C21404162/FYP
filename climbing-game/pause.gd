extends Control

@onready var pause_panel = $pause_panel
@onready var options_panel = $options_panel
@onready var saveload_panel = $saveload_panel
@onready var game_manager = GameManager

# Reference to the player character (you'll need to set this)
@export var player: Node3D

func _ready():
	# Hide the pause menu and options panel when the scene starts
	pause_panel.hide()
	options_panel.hide()
	saveload_panel.hide()
	# Ensure pause mode is set to process so the menu can work when the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	game_manager = get_tree().root.get_node_or_null("GameManager")
	
	# Add a null check to prevent errors
	if game_manager == null:
		print("Warning: GameManager not found in scene tree!")
		

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

func onsave_pressed():
	#print("Save button pressed")
	GameManager.save_game_data()

func onload_pressed():
	#print("Load button pressed")
	GameManager.load_game_data()

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
