extends Node3D

@onready var ambience = $ambience
@onready var fade_in = $Fade_interact/fade_in  
@onready var left_hand = $Player/lefthand
@onready var right_hand = $Player/righthand

func _ready() -> void:
	fade_in.play("fade_in")
	ambience.play()  # Start ambient sound
	#tween.interpolate_property(ambient_sound, "volume_db", -80, 0, 2.0)  # Fade in
	#tween.start()

func _process(delta: float) -> void:
	pass
