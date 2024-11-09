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
@export var reach_distance = 1.0
@export var reach_speed = 5.0
@export var climb_force = 20.0  # Force applied when climbing

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

func _ready():
	left_hand.gravity_scale = 0
	right_hand.gravity_scale = 0
	
	# Set up hands to collide with environment but not the player
	left_hand.collision_layer = 2   
	left_hand.collision_mask = 1|4  
	right_hand.collision_layer = 2
	right_hand.collision_mask = 1|4
	
	# Enable contact monitoring for grab detection
	left_hand.contact_monitor = true
	left_hand.max_contacts_reported = 1
	right_hand.contact_monitor = true
	right_hand.max_contacts_reported = 1
	
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
		
	# Handle reaching/grabbing input
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			left_hand_reaching = event.pressed
			if !event.pressed:  # Released left click
				left_hand_grabbing = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			right_hand_reaching = event.pressed
			if !event.pressed:  # Released right click
				right_hand_grabbing = false

func _physics_process(delta: float) -> void:
	check_grab_state()
	
	# Modified gravity handling for climbing
	if not is_on_floor() and not (left_hand_grabbing or right_hand_grabbing):
		velocity += get_gravity() * delta
	elif left_hand_grabbing or right_hand_grabbing:
		# Reduce or eliminate gravity while grabbing
		velocity.y = lerp(velocity.y, 0.0, delta * 10.0)
		
		# Allow climbing movement
		if Input.is_action_pressed("up"):  # Assuming "up" is your forward/climb up input
			velocity.y = climb_force * delta
		elif Input.is_action_pressed("down"):  # Add a down input in project settings
			velocity.y = -climb_force * delta
	
	# Handle jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or left_hand_grabbing or right_hand_grabbing:
			velocity.y = JUMP_VELOCITY
			# Release grab when jumping
			left_hand_grabbing = false
			right_hand_grabbing = false

	# Handle sprint
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	# Modified movement for climbing
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor() or not (left_hand_grabbing or right_hand_grabbing):
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		# Reduced horizontal movement while climbing
		velocity.x = lerp(velocity.x, direction.x * speed * 0.5, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed * 0.5, delta * 3.0)

	#headbob (disabled while climbing)
	if not (left_hand_grabbing or right_hand_grabbing):
		t_bob += delta * velocity.length() * float(is_on_floor())
		camera.transform.origin = _headbob(t_bob)

	#fov
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	update_hands(delta)
	move_and_slide()

func check_grab_state():
	# Check left hand
	if left_hand_reaching and left_hand.get_contact_count() > 0:
		if !left_hand_grabbing:
			grab_point_left = left_hand.global_position
			left_hand_grabbing = true
	
	# Check right hand
	if right_hand_reaching and right_hand.get_contact_count() > 0:
		if !right_hand_grabbing:
			grab_point_right = right_hand.global_position
			right_hand_grabbing = true

func update_hands(delta):
	var cam_basis = camera.global_transform.basis
	
	# Left hand position
	var left_target
	if left_hand_grabbing:
		left_target = grab_point_left
	else:
		left_target = camera.global_position + cam_basis * left_hand_initial_offset
		if left_hand_reaching:
			left_target += -cam_basis.z * reach_distance
	
	# Right hand position
	var right_target
	if right_hand_grabbing:
		right_target = grab_point_right
	else:
		right_target = camera.global_position + cam_basis * right_hand_initial_offset
		if right_hand_reaching:
			right_target += -cam_basis.z * reach_distance
	
	# Update positions
	left_hand.global_position = left_hand.global_position.lerp(left_target, delta * (reach_speed if left_hand_reaching else hand_smoothing))
	right_hand.global_position = right_hand.global_position.lerp(right_target, delta * (reach_speed if right_hand_reaching else hand_smoothing))

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
