extends CSGBox3D

@export var knock_sounds: Array[AudioStream]
@export var min_knock_delay: float = 3.0
@export var max_knock_delay: float = 8.0

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

# Sound tracking
var knock_timer: float = 0.0
var last_knock_index: int = -1  # Track last played sound

func _ready():
	audio_player.max_distance = 15.0  # Adjust this value (in meters)
	if knock_sounds.size() > 0:
		reset_knock_timer()

func _process(delta):
	if knock_sounds.size() == 0:
		return
		
	knock_timer -= delta
	if knock_timer <= 0:
		play_random_knock()
		reset_knock_timer()

func play_random_knock():
	# Select random sound different from last played
	var random_index = randi() % knock_sounds.size()
	while random_index == last_knock_index && knock_sounds.size() > 1:
		random_index = randi() % knock_sounds.size()
	last_knock_index = random_index
	
	audio_player.stream = knock_sounds[random_index]
	audio_player.pitch_scale = randf_range(0.9, 1.1)  # Slight pitch variation
	audio_player.volume_db = -20  # Adjust as needed
	audio_player.play()

func reset_knock_timer():
	knock_timer = randf_range(min_knock_delay, max_knock_delay)
