extends CharacterBody3D

var speed
const WALK_SPEED = 3.5
const SPRINT_SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.005

#headbob
const BOB_FREQ = 2.0
const BOB_AMP = 0.03
var t_bob = 0.0

#fov
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

@export var hand_smoothing = 20.0
@export var reach_distance = 0.8  # How far the hands can reach
@export var reach_speed = 15.0     # How fast the hands move when reaching

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var left_hand = $lefthand
@onready var right_hand = $righthand

# Store initial hand positions relative to camera
var left_hand_initial_offset: Vector3
var right_hand_initial_offset: Vector3

# Reach states
var left_hand_reaching = false
var right_hand_reaching = false

func _ready():
	left_hand.gravity_scale = 0
	right_hand.gravity_scale = 0
	
	# Set up hands to collide with environment but not the player
	left_hand.collision_layer = 2   
	left_hand.collision_mask = 1|4  
	right_hand.collision_layer = 2
	right_hand.collision_mask = 1|4
	
	# Make player ignore hand collisions
	collision_mask &= ~2  
	
	# Store the initial relative positions of hands to camera
	left_hand_initial_offset = left_hand.global_position - camera.global_position
	right_hand_initial_offset = right_hand.global_position - camera.global_position
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
		
	# Handle reaching input
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:  # Left click
			left_hand_reaching = event.pressed
		elif event.button_index == MOUSE_BUTTON_RIGHT:  # Right click
			right_hand_reaching = event.pressed

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle sprint
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	#headbob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	#fov
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	#update hand positions
	update_hands(delta)
	
	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func update_hands(delta):
	# Get the camera's rotation basis
	var cam_basis = camera.global_transform.basis
	
	# Calculate base target positions
	var left_target = camera.global_position + cam_basis * left_hand_initial_offset
	var right_target = camera.global_position + cam_basis * right_hand_initial_offset
	
	# Modify target positions based on reaching
	if left_hand_reaching:
		# Extend the left hand forward in the camera's direction
		left_target += -cam_basis.z * reach_distance
	
	if right_hand_reaching:
		# Extend the right hand forward in the camera's direction
		right_target += -cam_basis.z * reach_distance
	
	# Smooth movement
	left_hand.global_position = left_hand.global_position.lerp(left_target, delta * (reach_speed if left_hand_reaching else hand_smoothing))
	right_hand.global_position = right_hand.global_position.lerp(right_target, delta * (reach_speed if right_hand_reaching else hand_smoothing))
