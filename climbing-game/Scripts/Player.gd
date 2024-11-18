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

# Noclip state
var noclip_enabled = false

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
	
	# Noclip toggle
	if event.is_action_pressed("noclip"):
		noclip_enabled = !noclip_enabled
		if noclip_enabled:
			collision_mask = 0  # Disable collision
		else:
			collision_mask = LAYER_WORLD  # Restore world collision

func _physics_process(delta):
	check_grab_state()
	
	if noclip_enabled:
		handle_noclip(delta)
	elif left_hand_grabbing or right_hand_grabbing:
		handle_climbing(delta)
	else:
		handle_movement(delta)
	
	update_hands(delta)
	move_and_slide()

func handle_noclip(delta):
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var noclip_speed = SPRINT_SPEED * 2  # Faster movement in noclip
	var vertical_input = Input.get_action_strength("jump") - Input.get_action_strength("crouch")
	
	velocity = direction * noclip_speed
	velocity.y = vertical_input * noclip_speed

func handle_movement(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
		
		# Improved air control
		var input_dir = Input.get_vector("left", "right", "up", "down")
		var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var speed = SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
		
		if direction:
			# Smoother air control with reduced influence
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 5.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 5.0)
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
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 0.25)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 0.25)
	elif is_on_floor():
		velocity.x = lerp(velocity.x, 0.0, delta * 7.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 7.0)

func handle_climbing(delta):
	var hang_point: Vector3
	var forward_dir = camera.global_transform.basis.z

	if left_hand_grabbing and right_hand_grabbing:
		hang_point = (grab_point_left + grab_point_right) / 2
	else:
		hang_point = grab_point_left if left_hand_grabbing else grab_point_right
	
	var target_pos = hang_point + hang_offset
	velocity = velocity.lerp((target_pos - global_position) * climb_force, delta * 10.0)  # Added lerp for smoother movement
	
	if Input.is_action_just_pressed("jump"):
		left_hand_grabbing = false
		right_hand_grabbing = false
		velocity = -forward_dir * SPRINT_SPEED
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
	
	# Position update (same as before)
	var left_target = grab_point_left if left_hand_grabbing else \
		camera.global_position + cam_basis * left_hand_initial_offset + \
		(-cam_basis.z * reach_distance if left_hand_reaching else Vector3.ZERO)
	
	var right_target = grab_point_right if right_hand_grabbing else \
		camera.global_position + cam_basis * right_hand_initial_offset + \
		(-cam_basis.z * reach_distance if right_hand_reaching else Vector3.ZERO)
	
	# Position lerping (same as before)
	left_hand.global_position = left_hand.global_position.lerp(
		left_target,
		delta * (reach_speed if left_hand_reaching else hand_smoothing)
	)
	
	right_hand.global_position = right_hand.global_position.lerp(
		right_target,
		delta * (reach_speed if right_hand_reaching else hand_smoothing)
	)
	
	# Base rotations for non-grabbing state
	var left_adjustment = Basis().rotated(Vector3.FORWARD, deg_to_rad(180))
	var right_adjustment = Basis().rotated(Vector3.FORWARD, deg_to_rad(180))
	
	# Handle left hand rotation
	if left_hand_grabbing:
		var grab_dir = (grab_point_left - camera.global_position).normalized()
		var target_basis = Basis.looking_at(grab_dir, Vector3.UP)
		left_hand.global_transform.basis = left_hand.global_transform.basis.slerp(
			target_basis, 
			delta * hand_smoothing
		)
	else:
		# Always follow camera when not grabbing
		left_hand.global_transform.basis = left_hand.global_transform.basis.slerp(
			cam_basis * left_adjustment,
			delta * hand_smoothing
		)
	
	# Handle right hand rotation independently
	if right_hand_grabbing:
		var grab_dir = (grab_point_right - camera.global_position).normalized()
		var target_basis = Basis.looking_at(grab_dir, Vector3.UP)
		right_hand.global_transform.basis = right_hand.global_transform.basis.slerp(
			target_basis, 
			delta * hand_smoothing
		)
	else:
		# Always follow camera when not grabbing
		right_hand.global_transform.basis = right_hand.global_transform.basis.slerp(
			cam_basis * right_adjustment,
			delta * hand_smoothing
		)
