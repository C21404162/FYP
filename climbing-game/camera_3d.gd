extends Camera3D

# Sway parameters
var sway_amplitude_position: float = 0.015 
var sway_amplitude_rotation: float = 0.015 
var sway_frequency: float = 0.5         
var initial_position: Vector3          
var initial_rotation: Vector3       

func _ready():
	# Save the camera's initial position and rotation
	initial_position = transform.origin
	initial_rotation = rotation

func _process(delta):
	# Calculate sway using sine and cosine waves
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
