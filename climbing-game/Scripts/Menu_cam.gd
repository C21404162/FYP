extends Camera3D

var sway_amplitude_position: float = 0.015 
var sway_amplitude_rotation: float = 0.015 
var sway_frequency: float = 0.5         
var initial_position: Vector3          
var initial_rotation: Vector3       

func _ready():
	# Save initial position and rotation
	initial_position = transform.origin
	initial_rotation = rotation

func _process(delta):
	# Apply sway effect
	var time = Time.get_ticks_msec() / 1000.0
	var sway_offset_position = Vector3(
		sin(sway_frequency * time) * sway_amplitude_position,
		cos(sway_frequency * time) * sway_amplitude_position,
		0
	)
	
	var sway_offset_rotation = Vector3(
		cos(sway_frequency * time) * sway_amplitude_rotation,
		sin(sway_frequency * time) * sway_amplitude_rotation,
		0
	)
	
	transform.origin = initial_position + sway_offset_position
	rotation = initial_rotation + sway_offset_rotation

# Method to smoothly reset the camera to its initial position and rotation
func reset_camera_smoothly(duration: float = 0.5) -> void:
	var tween = create_tween()
	tween.set_parallel(true)  # Run position and rotation tweens simultaneously
	
	# Tween position
	tween.tween_property(self, "transform:origin", initial_position, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	# Tween rotation
	tween.tween_property(self, "rotation", initial_rotation, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
