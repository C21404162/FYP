extends Node3D

@onready var color_rect = $CanvasLayer/black_screen
@onready var fade_in = $Fade_interact/fade_in  
@onready var left_hand = $Player/lefthand
@onready var right_hand = $Player/righthand

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fade_in.play("fade_in")  

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
