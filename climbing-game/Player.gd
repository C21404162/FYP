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
const BASE_FOV = 90.0
const FOV_CHANGE = 1.5

# Added: Define collision layers as constants for clarity
const LAYER_WORLD = 1
const LAYER_HANDS = 2
const LAYER_PLAYER = 4

@export var hand_smoothing = 35.0
@export var reach_distance = 0.8
@export var reach_speed = 12.0
@export var climb_force = 10.0
@export var swing_strength = 10.0
@export var hang_distance = 30  # Distance below grab point when hanging
@export var swing_damping = 0.99  # How quickly swing momentum decreases
@export var max_swing_speed = 20.0  # Maximum swing velocity
@export var swing_acceleration = 40.0  # How quickly swing builds up

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var left_hand = $lefthand
@onready var right_hand = $righthand

# Store initial hand positions relative to camera
var left_hand_initial_offset: Vector3
var right_hand_initial_offset: Vector3

# Hand states
var left_hand_reaching = false
var right_hand_reaching = false
var left_hand_grabbing = false
var right_hand_grabbing = false
var grab_point_left: Vector3
var grab_point_right: Vector3

# Swing physics variables
var hang_direction: Vector3
var swing_velocity: Vector3
var swing_angle: float = 0.0
var swing_angular_velocity: float = 0.0

# New transition variables
var transition_to_hang = false
var transition_time = 0.0
const TRANSITION_DURATION = 0.5
var initial_grab_position: Vector3
var hang_offset = Vector3(0, -1.8, 0)  # Adjust based on your player's height

func _ready():
	left_hand.gravity_scale = 0
	right_hand.gravity_scale = 0
	
	# Updated collision setup for hands
	left_hand.collision_layer = LAYER_HANDS
	left_hand.collision_mask = LAYER_WORLD
	right_hand.collision_layer = LAYER_HANDS
	right_hand.collision_mask = LAYER_WORLD
	
	collision_layer = LAYER_PLAYER
	collision_mask = LAYER_WORLD
	
	left_hand.contact_monitor = true
	left_hand.max_contacts_reported = 1
	right_hand.contact_monitor = true
	right_hand.max_contacts_reported = 1
	
	left_hand_initial_offset = left_hand.global_position - camera.global_position
	right_hand_initial_offset = right_hand.global_position - camera.global_position
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			left_hand_reaching = event.pressed
			if !event.pressed:
				left_hand_grabbing = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			right_hand_reaching = event.pressed
			if !event.pressed:
				right_hand_grabbing = false

func _physics_process(delta: float) -> void:
	check_grab_state()
	
	if left_hand_grabbing or right_hand_grabbing:
		handle_climbing(delta)
	else:
		handle_normal_movement(delta)

	update_hands(delta)
	move_and_slide()

func handle_climbing(delta: float) -> void:
	var hang_point: Vector3
	var forward_dir: Vector3
	
	if left_hand_grabbing and right_hand_grabbing:
		# Two-handed hanging
		hang_point = (grab_point_left + grab_point_right) / 2
		hang_direction = (grab_point_right - grab_point_left).normalized()
		forward_dir = hang_direction.cross(Vector3.UP)
	else:
		# Single-handed hanging
		hang_point = grab_point_left if left_hand_grabbing else grab_point_right
		forward_dir = -head.global_transform.basis.z
		forward_dir.y = 0
		forward_dir = forward_dir.normalized()
		hang_direction = Vector3.RIGHT

	# Initialize transition when first grabbing
	if !transition_to_hang:
		transition_to_hang = true
		transition_time = 0.0
		initial_grab_position = global_position
		# Initialize swing velocity based on current movement
		swing_velocity = velocity
		swing_velocity.y = 0  # Remove vertical component
	
	# Update transition
	if transition_to_hang:
		transition_time = min(transition_time + delta, TRANSITION_DURATION)
		var t = ease(transition_time / TRANSITION_DURATION, 0.5)  # Smooth easing
		
		# Calculate ideal hanging position
		var ideal_pos = hang_point + hang_offset
		
		# Apply swing physics
		var input_dir = Input.get_vector("left", "right", "up", "down")
		if input_dir != Vector2.ZERO:
			var swing_dir = (forward_dir * input_dir.y + hang_direction * input_dir.x).normalized()
			swing_velocity += swing_dir * swing_acceleration * delta
		
		# Apply swing limits and damping
		swing_velocity = swing_velocity.limit_length(max_swing_speed)
		swing_velocity *= swing_damping
		
		# Calculate final position with swing
		var target_pos = ideal_pos + swing_velocity * delta
		
		# Blend between current position and target position during transition
		if transition_time < TRANSITION_DURATION:
			target_pos = initial_grab_position.lerp(target_pos, t)
		
		# Smoothly move to target position
		velocity = (target_pos - global_position) * climb_force
		
		# Apply some pendulum-like motion
		if t > 0.1:  # Start pendulum after initial grab
			var to_center = (hang_point - global_position)
			var pendulum_force = to_center.normalized() * (to_center.length() - hang_distance) * climb_force
			velocity += pendulum_force * delta
	
	# Allow letting go with jump - now with better momentum preservation
	if Input.is_action_just_pressed("jump"):
		var release_velocity = swing_velocity  # Store current swing velocity
		var forward_boost = -head.global_transform.basis.z * 5.0  # Forward direction
		
		# Calculate release direction based on swing
		var release_direction = (release_velocity.normalized() + forward_boost.normalized()).normalized()
		var total_speed = release_velocity.length() + 5.0  # Combine swing speed with base jump speed
		
		left_hand_grabbing = false
		right_hand_grabbing = false
		transition_to_hang = false
		
		# Apply the combined velocity
		velocity = release_direction * total_speed
		velocity.y = JUMP_VELOCITY  # Add upward boost

func handle_normal_movement(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Only apply gravity and air resistance when not on floor
	if not is_on_floor():
		velocity += get_gravity() * delta
		# Apply air resistance to horizontal movement
		var horizontal_velocity = Vector2(velocity.x, velocity.z)
		var air_resistance = 1.0 - (delta * 0.8)  # Adjust this value to control air resistance
		horizontal_velocity *= air_resistance
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.y
	
	speed = SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Only override horizontal velocity with input if on floor or input is significant
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, 0.0, delta * 7.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 7.0)
	else:
		# Air control - allow some influence over momentum while in air
		if direction:
			var air_control = 0.3  # Adjust this value to control air maneuverability
			velocity.x = lerp(velocity.x, direction.x * speed, delta * air_control)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * air_control)
	
	# Headbob and FOV updates
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

func check_grab_state():
	if left_hand_reaching and left_hand.get_contact_count() > 0:
		if !left_hand_grabbing:
			grab_point_left = left_hand.global_position
			left_hand_grabbing = true
			transition_to_hang = false  # Reset transition when grabbing new point
	
	if right_hand_reaching and right_hand.get_contact_count() > 0:
		if !right_hand_grabbing:
			grab_point_right = right_hand.global_position
			right_hand_grabbing = true
			transition_to_hang = false  # Reset transition when grabbing new point

func update_hands(delta):
	var cam_basis = camera.global_transform.basis
	
	var left_target
	if left_hand_grabbing:
		left_target = grab_point_left
	else:
		left_target = camera.global_position + cam_basis * left_hand_initial_offset + \
			(-cam_basis.z * reach_distance if left_hand_reaching else Vector3.ZERO)
	
	var right_target
	if right_hand_grabbing:
		right_target = grab_point_right
	else:
		right_target = camera.global_position + cam_basis * right_hand_initial_offset + \
			(-cam_basis.z * reach_distance if right_hand_reaching else Vector3.ZERO)
	
	left_hand.global_position = left_hand.global_position.lerp(
		left_target, 
		delta * (reach_speed if left_hand_reaching else hand_smoothing)
	)
	right_hand.global_position = right_hand.global_position.lerp(
		right_target, 
		delta * (reach_speed if right_hand_reaching else hand_smoothing)
	)

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
