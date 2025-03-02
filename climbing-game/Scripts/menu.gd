extends Control

#cam
@onready var Camera: Camera3D = $Camera3D

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

func _ready() -> void:
	
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
	get_tree().change_scene_to_file("res://world.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_mouse_entered_start():
	if ogham_label_start and english_label_start:
		create_tween().tween_property(ogham_label_start, "modulate", Color(1, 1, 1, 0), 0.7)
		create_tween().tween_property(english_label_start, "modulate", Color(1, 1, 1, 1), 0.7)

func _on_mouse_entered_options():
	if ogham_label_options and english_label_options:
		create_tween().tween_property(ogham_label_options, "modulate", Color(1, 1, 1, 0), 0.7)
		create_tween().tween_property(english_label_options, "modulate", Color(1, 1, 1, 1), 0.7)

func _on_mouse_entered_exit():
	if ogham_label_exit and english_label_exit:
		create_tween().tween_property(ogham_label_exit, "modulate", Color(1, 1, 1, 0), 0.7)
		create_tween().tween_property(english_label_exit, "modulate", Color(1, 1, 1, 1), 0.7)

func _on_mouse_entered_continue() -> void:
	if ogham_label_continue and english_label_continue:
		create_tween().tween_property(ogham_label_continue, "modulate", Color(1, 1, 1, 0), 0.7)
		create_tween().tween_property(english_label_continue, "modulate", Color(1, 1, 1, 1), 0.7)

func _on_continue_pressed() -> void:
	print("Continue button pressed. Loading game data...")
	game_manager.load_game_data()
	print("Game data loaded. Changing scene...")
	get_tree().change_scene_to_file("res://world.tscn")
