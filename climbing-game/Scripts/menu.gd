extends Control

@onready var ogham_label_start: Label = $VBoxContainer/start/ogham_label_start
@onready var english_label_start: Label = $VBoxContainer/start/english_label_start
@onready var ogham_label_options: Label = $VBoxContainer/options/ogham_label_options
@onready var english_label_options: Label = $VBoxContainer/options/english_label_options
@onready var ogham_label_exit: Label = $VBoxContainer/exit/ogham_label_exit
@onready var english_label_exit: Label = $VBoxContainer/exit/english_label_exit

func _ready() -> void:
	# Initialize visibility
	ogham_label_start.modulate = Color(1, 1, 1, 1)  # Ogham visible
	english_label_start.modulate = Color(1, 1, 1, 0)  # English hidden
	ogham_label_options.modulate = Color(1, 1, 1, 1)  # Ogham visible
	english_label_options.modulate = Color(1, 1, 1, 0)  # English hidden
	ogham_label_exit.modulate = Color(1, 1, 1, 1)  # Ogham visible
	english_label_exit.modulate = Color(1, 1, 1, 0)  # English hidden

	# Focus the first button
	$VBoxContainer/start.grab_focus()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://world.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_mouse_entered_start():
	if ogham_label_start and english_label_start:
		# Fade out Ogham label
		create_tween().tween_property(ogham_label_start, "modulate", Color(1, 1, 1, 0), 0.7)
		# Fade in English label
		create_tween().tween_property(english_label_start, "modulate", Color(1, 1, 1, 1), 0.7)

func _on_mouse_entered_options():
	if ogham_label_options and english_label_options:
		# Fade out Ogham label
		create_tween().tween_property(ogham_label_options, "modulate", Color(1, 1, 1, 0), 0.7)
		# Fade in English label
		create_tween().tween_property(english_label_options, "modulate", Color(1, 1, 1, 1), 0.7)

func _on_mouse_entered_exit():
	if ogham_label_exit and english_label_exit:
		# Fade out Ogham label
		create_tween().tween_property(ogham_label_exit, "modulate", Color(1, 1, 1, 0), 0.7)
		# Fade in English label
		create_tween().tween_property(english_label_exit, "modulate", Color(1, 1, 1, 1), 0.7)
