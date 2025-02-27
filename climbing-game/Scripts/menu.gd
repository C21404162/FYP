extends Control

@onready var ogham_label_start: Label = $VBoxContainer/options/ogham_label_start
@onready var ogham_label_options: Label = $VBoxContainer/options/ogham_label_options
@onready var ogham_label_exit: Label = $VBoxContainer/options/ogham_label_exit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/start.grab_focus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://world.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_mouse_entered_start():
	if ogham_label_start:
		create_tween().tween_property(ogham_label_start, "modulate", Color(1, 1, 1, 0), 0.5)

func _on_mouse_entered_options():
	if ogham_label_options:
		create_tween().tween_property(ogham_label_options, "modulate", Color(1, 1, 1, 0), 0.5)

func _on_mouse_entered_exit():
	if ogham_label_exit:
		create_tween().tween_property(ogham_label_exit, "modulate", Color(1, 1, 1, 0), 0.5)
