extends CharacterBody3D

# Movement
const WALK_SPEED = 3.5
const SPRINT_SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.005
const MAX_JUMP_CHARGE_TIME = 1.0 
const MIN_CHARGE_FOR_BOOST = 0.3
const MAX_JUMP_BOOST = 1.5 

# Collision layers
const LAYER_WORLD = 1
const LAYER_HANDS = 2
const LAYER_PLAYER = 4

# Physics stuff
@export var hand_smoothing = 35.0
@export var reach_distance = 0.7
@export var reach_speed = 12.5
@export var climb_force = 7.0
@export var hang_offset = Vector3(0, -1.8, 0)

# Nodes
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var left_hand = $lefthand
@onready var right_hand = $righthand
@onready var grab_sound = $"../grabsound"
@onready var hand_fx = $"../Map/GPUParticles3D"

# Raycasts
@onready var left_hand_raycast = $lefthand/left_hand_raycast
@onready var right_hand_raycast = $righthand/right_hand_raycast

# Joints for climbing
@onready var grab_joint_left = $lefthand/PinJoint3D_Left
@onready var grab_joint_right = $righthand/PinJoint3D_Right

# Climb variables
var left_hand_initial_offset: Vector3
var right_hand_initial_offset: Vector3
var left_hand_reaching = false
var right_hand_reaching = false
var left_hand_grabbing = false
var right_hand_grabbing = false
var grab_point_left: Vector3
var grab_point_right: Vector3
var is_charging_jump = false
var jump_charge_time = 0.0
var noclip_enabled = false

# Landing 
var was_in_air = false
@onready var landing_particles = $LandingParticles

# Gravity
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Pause menu
@export var pause_menu_scene_path: String = "res://pause.tscn"
var pause_menu_instance: Control = null

# Game manager
@onready var game_manager = get_node("/root/GameManager")

func _ready():
	
	# Configure joint properties using set_param
	grab_joint_left.set_param(PinJoint3D.PARAM_BIAS, 1.0)  # Adjust stiffness (0.0 to 1.0)
	grab_joint_left.set_param(PinJoint3D.PARAM_DAMPING, 0.2)  # Adjust damping (0.0 to 1.0)
	grab_joint_left.set_param(PinJoint3D.PARAM_IMPULSE_CLAMP, 5.0)  # Maximum impulse the joint can apply
	
	grab_joint_right.set_param(PinJoint3D.PARAM_BIAS, 0.5)  # Adjust stiffness (0.0 to 1.0)
	grab_joint_right.set_param(PinJoint3D.PARAM_DAMPING, 0.8)  # Adjust damping (0.0 to 1.0)
	grab_joint_right.set_param(PinJoint3D.PARAM_IMPULSE_CLAMP, 10.0)  # Maximum impulse the joint can apply
	
	camera.fov = GameManager.fov
	GameManager.connect("fov_updated", Callable(self, "_on_fov_updated"))
	
	var pause_menu_scene = load(pause_menu_scene_path)
	if pause_menu_scene:
		print("Pause menu scene loaded successfully.")
		pause_menu_instance = pause_menu_scene.instantiate()
		if pause_menu_instance:
			print("Pause menu instance created successfully.")
			add_child(pause_menu_instance)
			pause_menu_instance.hide()
		else:
			print("Failed to instantiate pause menu scene.")
	else:
		print("Failed to load pause menu scene.")
	
	# Cam setup
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	setup_hands()
	left_hand_initial_offset = left_hand.global_position - camera.global_position
	right_hand_initial_offset = right_hand.global_position - camera.global_position
	setup_game_manager_connection()
	
	spawn_falling()

func spawn_falling():
	global_transform.origin = $"/root/World/Map/SpawnPoint".global_transform.origin

func _on_fov_updated(new_fov: float):
	camera.fov = new_fov

func _on_player_position_updated(position: Vector3):
	global_position = position

func _on_player_rotation_updated(rotation: Basis):
	$Head.global_transform.basis = rotation

func setup_game_manager_connection():
	if game_manager:
		game_manager.connect("player_position_updated", _on_player_position_updated)
		game_manager.connect("player_rotation_updated", _on_player_rotation_updated)
	else:
		print("Error: Game Manager node not found.")

func setup_hands():
	left_hand.gravity_scale = 0
	right_hand.gravity_scale = 0
	left_hand.collision_layer = LAYER_HANDS
	left_hand.collision_mask = LAYER_WORLD
	right_hand.collision_layer = LAYER_HANDS
	right_hand.collision_mask = LAYER_WORLD
	collision_layer = LAYER_PLAYER
	collision_mask = LAYER_WORLD
	
	left_hand.contact_monitor = true
	right_hand.contact_monitor = true
	left_hand.max_contacts_reported = 1
	right_hand.max_contacts_reported = 1

func _unhandled_input(event):
	# Pause
	if event.is_action_pressed("esc"):
		if pause_menu_instance:
			if pause_menu_instance.is_inside_tree():
				pause_menu_instance.toggle_pause()
			else:
				print("Pause menu instance is not part of the SceneTree!")
		else:
			print("Pause menu instance not found!")
	
	# Mouse movement
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				left_hand_reaching = event.pressed
				if !event.pressed: release_grab(true)
			MOUSE_BUTTON_RIGHT:
				right_hand_reaching = event.pressed
				if !event.pressed: release_grab(false)
	
	# Noclip toggle
	if event.is_action_pressed("noclip"):
		noclip_enabled = !noclip_enabled
		if noclip_enabled:
			collision_mask = 0 
		else:
			collision_mask = LAYER_WORLD

func _physics_process(delta):
	
	check_grab()
	
	# Game manager updates
	GameManager.update_player_position(global_transform.origin)
	var camera_rotation = $Head.global_transform.basis
	GameManager.update_player_position(global_transform.origin)
	GameManager.update_player_rotation(camera_rotation)
	
	if noclip_enabled:
		handle_noclip(delta)
	elif left_hand_grabbing or right_hand_grabbing:
		handle_climbing(delta)
	else:
		handle_movement(delta)
	
	update_hands(delta)
	move_and_slide()
	
	# Landing logic
	if !was_in_air and is_on_floor():
		emit_landing_particles()
	was_in_air = !is_on_floor()

func emit_landing_particles():
	if landing_particles:
		landing_particles.global_transform.origin = global_transform.origin
		landing_particles.emitting = true

func handle_noclip(delta):
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var noclip_speed = SPRINT_SPEED * 2
	var vertical_input = Input.get_action_strength("jump") - Input.get_action_strength("crouch")
	velocity = direction * noclip_speed
	velocity.y = vertical_input * noclip_speed

func handle_movement(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
		
		var input_dir = Input.get_vector("left", "right", "up", "down")
		var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var speed = SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
		
		if direction:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
	
	var speed = SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Crouch
	if Input.is_action_pressed("crouch"):
		speed *= 0.6
	
	# Lerp
	if direction:
		if is_on_floor():
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 12.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 12.0)
	else:
		velocity.x = lerp(velocity.x, 0.0, delta * 10.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 10.0)

func handle_climbing(delta):
	# Apply gravity even while climbing
	velocity.y -= gravity * delta
	
	# Calculate pull force based on input
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var pull_force = Vector3.ZERO
	
	if left_hand_grabbing:
		var dir_to_grab = (grab_point_left - global_position).normalized()
		var distance_to_grab = global_position.distance_to(grab_point_left)
		if distance_to_grab > reach_distance:
			pull_force += dir_to_grab * (distance_to_grab - reach_distance) * climb_force
	
	if right_hand_grabbing:
		var dir_to_grab = (grab_point_right - global_position).normalized()
		var distance_to_grab = global_position.distance_to(grab_point_right)
		if distance_to_grab > reach_distance:
			pull_force += dir_to_grab * (distance_to_grab - reach_distance) * climb_force
	
	# Apply pull force to velocity
	velocity += pull_force * delta

func check_grab():
	# Left hand grab logic
	if left_hand_reaching and not left_hand_grabbing:
		if left_hand_raycast.is_colliding():
			var collider = left_hand_raycast.get_collider()
			if collider and collider.is_in_group("Climbable"):
				grab_object(left_hand_raycast, true)
				print("Left hand grabbed: ", collider.name)
				
				# Particles and sound
				particles_hand(grab_point_left)
				grab_sound.play()

	# Right hand grab logic
	if right_hand_reaching and not right_hand_grabbing:
		if right_hand_raycast.is_colliding():
			var collider = right_hand_raycast.get_collider()
			if collider and collider.is_in_group("Climbable"):
				grab_object(right_hand_raycast, false)
				print("Right hand grabbed: ", collider.name)
				
				# Particles and sound
				particles_hand(grab_point_right)
				grab_sound.play()

func grab_object(hand_raycast: RayCast3D, is_left_hand: bool):
	if hand_raycast.is_colliding():
		var grab_point = hand_raycast.get_collision_point()
		var grab_joint = grab_joint_left if is_left_hand else grab_joint_right
		var collider = hand_raycast.get_collider()
		
		# Position the joint at the grab point
		grab_joint.global_transform.origin = grab_point
		
		# Enable the joint by connecting it to the player and the collider
		grab_joint.node_a = self.get_path()  # Player is node_a
		grab_joint.node_b = collider.get_path()  # Collider is node_b
		
		# Store grab point for reference
		if is_left_hand:
			grab_point_left = grab_point
			left_hand_grabbing = true
		else:
			grab_point_right = grab_point
			right_hand_grabbing = true
		
		print("Grabbed with", "left" if is_left_hand else "right", "hand at:", grab_point)

func release_grab(is_left_hand: bool):
	var grab_joint = grab_joint_left if is_left_hand else grab_joint_right
	
	# Disable the joint by clearing node_b
	grab_joint.node_b = NodePath("")
	
	if is_left_hand:
		left_hand_grabbing = false
	else:
		right_hand_grabbing = false
	
	# Preserve momentum
	velocity = velocity
	
	print("Released", "left" if is_left_hand else "right", "hand")

func update_hands(delta):
	var cam_basis = camera.global_transform.basis
	
	# If grab move to grab point, if reaching extend from camera, if not grab return to default
	var left_target = grab_point_left if left_hand_grabbing else \
		camera.global_position + cam_basis * left_hand_initial_offset + \
		(-cam_basis.z * reach_distance if left_hand_reaching else Vector3.ZERO)
	
	var right_target = grab_point_right if right_hand_grabbing else \
		camera.global_position + cam_basis * right_hand_initial_offset + \
		(-cam_basis.z * reach_distance if right_hand_reaching else Vector3.ZERO)
	
	# Hand movement left
	left_hand.global_position = left_hand.global_position.lerp(
		left_target,
		delta * (reach_speed if left_hand_reaching else hand_smoothing)
	)
	# Hand movement right
	right_hand.global_position = right_hand.global_position.lerp(
		right_target,
		delta * (reach_speed if right_hand_reaching else hand_smoothing)
	)

func particles_hand(contact_point):
	hand_fx.global_position = contact_point
	hand_fx.emitting = true
