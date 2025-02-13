extends Node3D

@onready var color_rect = $CanvasLayer/black_screen
@onready var fade_in = $CanvasLayer/fade_in  # Ensure this is the correct path to your AnimationPlayer
@onready var left_hand = $Player/lefthand
@onready var right_hand = $Player/righthand

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fade_in.play("fade_in")  # Play the "fade_in" animation

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
