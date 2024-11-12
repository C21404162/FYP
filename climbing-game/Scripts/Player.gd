extends CharacterBody3D

# Movement constants
const WALK_SPEED = 3.5
const SPRINT_SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.005

# Physics & climbing settings
@export var hand_smoothing = 35.0
@export var reach_distance = 0.9
@export var reach_speed = 12.0
@export var climb_force = 10.0
@export var hang_offset = Vector3(0, -1.8, 0)

# Collision layers
const LAYER_WORLD = 1
const LAYER_HANDS = 2
const LAYER_PLAYER = 4

# Node references
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var left_hand = $lefthand
@onready var right_hand = $righthand

# Store initial hand positions
var left_hand_initial_offset: Vector3
var right_hand_initial_offset: Vector3

# Hand states
var left_hand_reaching = false
var right_hand_reaching = false
var left_hand_grabbing = false
var right_hand_grabbing = false
var grab_point_left: Vector3
var grab_point_right: Vector3

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	setup_hands()
	
	# Store initial hand offsets
	left_hand_initial_offset = left_hand.global_position - camera.global_position
	right_hand_initial_offset = right_hand.global_position - camera.global_position

func setup_hands():
	left_hand.gravity_scale = 0
	right_hand.gravity_scale = 0
	
	# Set up collision layers
	left_hand.collision_layer = LAYER_HANDS
	left_hand.collision_mask = LAYER_WORLD
	right_hand.collision_layer = LAYER_HANDS
	right_hand.collision_mask = LAYER_WORLD
	collision_layer = LAYER_PLAYER
	collision_mask = LAYER_WORLD
	
	# Enable contact monitoring
	left_hand.contact_monitor = true
	right_hand.contact_monitor = true
	left_hand.max_contacts_reported = 1
	right_hand.max_contacts_reported = 1

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				left_hand_reaching = event.pressed
				if !event.pressed: left_hand_grabbing = false
			MOUSE_BUTTON_RIGHT:
				right_hand_reaching = event.pressed
				if !event.pressed: right_hand_grabbing = false

func _physics_process(delta):
	check_grab_state()
	
	if left_hand_grabbing or right_hand_grabbing:
		handle_climbing(delta)
	else:
		handle_movement(delta)
	
	update_hands(delta)
	move_and_slide()

func handle_movement(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
		# Air control
		var air_control = 0.3
		if velocity.length() > 0:
			velocity.x *= 0.99
			velocity.z *= 0.99
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
	
	var speed = SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		if is_on_floor():
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 0.3)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 0.3)
	elif is_on_floor():
		velocity.x = lerp(velocity.x, 0.0, delta * 7.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 7.0)

func handle_climbing(delta):
	var hang_point: Vector3
	var forward_dir = -camera.global_transform.basis.z
	
	if left_hand_grabbing and right_hand_grabbing:
		hang_point = (grab_point_left + grab_point_right) / 2
	else:
		hang_point = grab_point_left if left_hand_grabbing else grab_point_right
	
	var target_pos = hang_point + hang_offset
	velocity = (target_pos - global_position) * climb_force
	
	if Input.is_action_just_pressed("jump"):
		left_hand_grabbing = false
		right_hand_grabbing = false
		velocity = forward_dir * SPRINT_SPEED
		velocity.y = JUMP_VELOCITY

func check_grab_state():
	if left_hand_reaching and left_hand.get_contact_count() > 0 and !left_hand_grabbing:
		grab_point_left = left_hand.global_position
		left_hand_grabbing = true
	
	if right_hand_reaching and right_hand.get_contact_count() > 0 and !right_hand_grabbing:
		grab_point_right = right_hand.global_position
		right_hand_grabbing = true

func update_hands(delta):
	var cam_basis = camera.global_transform.basis
	
	var left_target = grab_point_left if left_hand_grabbing else \
		camera.global_position + cam_basis * left_hand_initial_offset + \
		(-cam_basis.z * reach_distance if left_hand_reaching else Vector3.ZERO)
	
	var right_target = grab_point_right if right_hand_grabbing else \
		camera.global_position + cam_basis * right_hand_initial_offset + \
		(-cam_basis.z * reach_distance if right_hand_reaching else Vector3.ZERO)
	
	left_hand.global_position = left_hand.global_position.lerp(
		left_target,
		delta * (reach_speed if left_hand_reaching else hand_smoothing)
	)
	
	right_hand.global_position = right_hand.global_position.lerp(
		right_target,
		delta * (reach_speed if right_hand_reaching else hand_smoothing)
	)
