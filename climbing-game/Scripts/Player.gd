extends CharacterBody3D

# Movement
const WALK_SPEED = 3.5
const SPRINT_SPEED = 5.0
const JUMP_VELOCITY = 4.5
var SENSITIVITY = 0.001
const MAX_JUMP_CHARGE_TIME = 1.0 
const MIN_CHARGE_FOR_BOOST = 0.3
const MAX_JUMP_BOOST = 1.5 
const MAX_GRAB_DISTANCE = 3.00

# Collision layers
const LAYER_WORLD = 1
const LAYER_HANDS = 2
const LAYER_PLAYER = 4

# Physics stuff
@export var hand_smoothing = 20
@export var reach_distance = 0.6
@export var reach_speed = 10.0
@export var climb_force = 5.0
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
@onready var grab_joint_left = $HingeJoint3D_Left
@onready var grab_joint_right = $HingeJoint3D_Right

@onready var hand_animation_player_left = $lefthand/hand_left_rigged/AnimationPlayer
@onready var hand_animation_player_right = $righthand/hand_right_rigged/AnimationPlayer

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
var left_hand_rotation_locked = false
var right_hand_rotation_locked = false

var velocity_decay_rate: float = 5.0 

# Landing 
var was_in_air = false
@onready var landing_particles = $LandingParticles

# Grab sounds
@export var grab_sounds: Array[AudioStream] = []
@onready var left_hand_sound = $lefthand/grab_sound_left
@onready var right_hand_sound = $righthand/grab_sound_right
var last_grab_sound_index = -1

# Break sounds
@export var rock_break_sounds: Array[AudioStream] = []
@onready var rock_break_sound = $"../rock_break_sound"
# Gravel warning sounds
@export var gravel_warning_sounds: Array[AudioStream] = []
@onready var gravel_warning_sound = $"../gravelwarningsound"


# Rock spawning variables
@export var rock_scene: PackedScene 
@export var rock_spawn_position: Vector3  
var rock_instance: RigidBody3D = null  
@onready var area_3d = $"../Map/Area3D"
@onready var rockfall_sound = $rockfall

var left_hand_cooldown = 0.0
var right_hand_cooldown = 0.0
const GRAB_COOLDOWN_TIME = 0.3  

# Reach sounds
@export var hand_reach_sounds: Array[AudioStream] = []
@onready var hand_reach_sound = $hand_reach_sound

# Gravity
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Pause menu
@export var pause_menu_scene_path: String = "res://pause.tscn"
var pause_menu_instance: Control = null

# Game manager
@onready var game_manager = get_node("/root/GameManager")

# Breaking
var grab_timers: Dictionary = {}  
var broken_surfaces: Dictionary = {}  
const BREAK_TIME: float = 3.0  
const RESPAWN_TIME: float = 5.0  
const WARNING_TIME: float = 1.0  
var warning_sound_played: Dictionary = {}  

# Falling effects
@export var landing_sounds: Array[AudioStream] = []
@export var wind_woosh_sounds: Array[AudioStream] = []
@onready var landing_sound = $Landing_sound
@onready var wind_woosh_sound = $Falling_sound
var is_falling = false
var fall_time = 0.0
const FALL_SHAKE_INTENSITY = 0.1
const FALL_SHAKE_SPEED = 10.0
const MIN_FALL_TIME = 2.0
var last_landing_sound_index = -1

# Breakable wood variables
@export var wood_break_sounds: Array[AudioStream] = []
@onready var wood_break_sound = $"../gravelwarningsound"
const WOOD_BREAK_FORCE = 40.0  # Minimum force required to break wood
const WOOD_BREAK_TORQUE = 20.0   # Minimum torque required to break wood
var left_hand_pull_force = Vector3.ZERO
var right_hand_pull_force = Vector3.ZERO
var left_hand_torque = 0.0
var right_hand_torque = 0.0

func _ready():
	# Set FOV from GameManager
	camera.fov = GameManager.fov
	GameManager.connect("fov_updated", Callable(self, "_on_fov_updated"))
	
	if area_3d:
		area_3d.collision_mask = 1 | 4  # Include Layers 1 and 4
	if area_3d:
		area_3d.connect("body_entered", Callable(self, "_on_area_3d_body_entered"))
	
	setup_hands()

	SENSITIVITY = game_manager.sensitivity
	game_manager.connect("sensitivity_updated", Callable(self, "_on_sensitivity_updated"))
	
	# Load pause menu
	var pause_menu_scene = load(pause_menu_scene_path)
	if pause_menu_scene:
		pause_menu_instance = pause_menu_scene.instantiate()
		if pause_menu_instance:
			add_child(pause_menu_instance)
			pause_menu_instance.hide()
		else:
			print("Failed to instantiate pause menu scene.")
	else:
		print("Failed to load pause menu scene.")
	
	# Cam setup
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	left_hand_initial_offset = left_hand.global_position - camera.global_position
	right_hand_initial_offset = right_hand.global_position - camera.global_position
	setup_game_manager_connection()
	
	# Spawn falling if no save
	if GameManager.player_position == Vector3.ZERO:
		spawn_falling()
	else:
		# Saved pos and rot
		global_transform.origin = GameManager.player_position
		$Head.global_transform.basis = GameManager.player_rotation

func configure_hinge_joint(joint: HingeJoint3D):
	# Enable angular limits
	joint.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	
	# Set angular limits
	joint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, -0.1) 
	joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, 0.1) 
	
	# Set bias and relaxation for stiffness
	joint.set_param(HingeJoint3D.PARAM_LIMIT_BIAS, 10)  
	joint.set_param(HingeJoint3D.PARAM_LIMIT_RELAXATION, 0.1) 

func spawn_falling():
	global_transform.origin = $"/root/World/Map/SpawnPoint".global_transform.origin

func _on_fov_updated(new_fov: float):
	camera.fov = new_fov
	
func _on_sensitivity_updated(new_sensitivity: float):
	SENSITIVITY = new_sensitivity
	print("Sensitivity updated to: ", SENSITIVITY)

func _on_player_position_updated(position: Vector3):
	global_position = position

func _on_player_rotation_updated(rotation: Basis):
	$Head.global_transform.basis = rotation

func setup_game_manager_connection():
	if game_manager:
		game_manager.connect("player_position_updated", Callable(self, "_on_player_position_updated"))
		game_manager.connect("player_rotation_updated", Callable(self, "_on_player_rotation_updated"))
	else:
		print("*GAME MANAGER NOT FOUND")

func setup_hands():
	left_hand.gravity_scale = 0
	right_hand.gravity_scale = 0
	left_hand.collision_layer = LAYER_HANDS
	left_hand.collision_mask = LAYER_WORLD
	right_hand.collision_layer = LAYER_HANDS
	right_hand.collision_mask = LAYER_WORLD
	
	# Update the player's collision mask to include Layer 1 (Area3D's layer)
	collision_layer = LAYER_PLAYER
	collision_mask = LAYER_WORLD | 1  # Include Layer 1 in the mask
	
	left_hand.contact_monitor = true
	right_hand.contact_monitor = true
	left_hand.max_contacts_reported = 1
	right_hand.max_contacts_reported = 1
	
	left_hand.mass = 1.0
	right_hand.mass = 1.0
	left_hand.inertia = Vector3(1, 1, 1)
	right_hand.inertia = Vector3(1, 1, 1)

func _unhandled_input(event):
	# Pause
	if event.is_action_pressed("esc"):
		if pause_menu_instance:
			if pause_menu_instance.is_inside_tree():
				pause_menu_instance.toggle_pause()
	
	# Mouse movement
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	# Grab binds
	if event.is_action_pressed("grab_left"):
		hand_animation_player_left.play("open")
		left_hand_reaching = true
		
		# Play random reach sound for left hand
		if hand_reach_sounds.size() > 0:
			var random_index = randi() % hand_reach_sounds.size()
			# Ensure the same sound isn't played twice in a row
			while random_index == last_grab_sound_index:
				random_index = randi() % hand_reach_sounds.size()
			last_grab_sound_index = random_index

			# Set random pitch and volume
			var pitch = randf_range(0.9, 1.1)  
			var volume_db = -30  

			# Play the sound on the left hand
			left_hand_sound.volume_db = volume_db
			left_hand_sound.pitch_scale = pitch
			left_hand_sound.stream = hand_reach_sounds[random_index]
			left_hand_sound.play()
		
	elif event.is_action_released("grab_left"):
		hand_animation_player_left.play("default")
		left_hand_reaching = false
		release_grab(true)

	if event.is_action_pressed("grab_right"):
		hand_animation_player_right.play("open")
		right_hand_reaching = true
		
		# Play random reach sound for right hand
		if hand_reach_sounds.size() > 0:
			var random_index = randi() % hand_reach_sounds.size()
			# Ensure the same sound isn't played twice in a row
			while random_index == last_grab_sound_index:
				random_index = randi() % hand_reach_sounds.size()
			last_grab_sound_index = random_index

			# Set random pitch and volume
			var pitch = randf_range(0.9, 1.1) 
			var volume_db = -30 

			# Play the sound on the right hand
			right_hand_sound.volume_db = volume_db
			right_hand_sound.pitch_scale = pitch
			right_hand_sound.stream = hand_reach_sounds[random_index]
			right_hand_sound.play()
		
	elif event.is_action_released("grab_right"):
		hand_animation_player_right.play("default")
		right_hand_reaching = false
		release_grab(false)
				
	# Noclip toggle
	if event.is_action_pressed("noclip"):
		noclip_enabled = !noclip_enabled
		if noclip_enabled:
			collision_mask = 0 
		else:
			collision_mask = LAYER_WORLD

func _physics_process(delta):
	
	if left_hand_cooldown > 0:
		left_hand_cooldown -= delta
	if right_hand_cooldown > 0:
		right_hand_cooldown -= delta

	# Existing collision check
	var collision = get_last_slide_collision()
	if collision:
		var collider = collision.get_collider()
		if collider and collider.is_in_group("rock"):  # Ensure the rock is in the "Rock" group
			print("Player collided with rock! Releasing grabs...")  # Debug: Confirm collision
			if left_hand_grabbing:
				hand_animation_player_left.play("default")
				release_grab(true)  # Release left hand
				left_hand_cooldown = GRAB_COOLDOWN_TIME  # Start cooldown for left hand
			if right_hand_grabbing:
				hand_animation_player_right.play("default")
				release_grab(false)  # Release right hand
				right_hand_cooldown = GRAB_COOLDOWN_TIME  # Start cooldown for right hand
	
	if left_hand_grabbing:
		left_hand.global_transform.origin = grab_point_left
	if right_hand_grabbing:
		right_hand.global_transform.origin = grab_point_right
	
	check_area_collision()
	
	check_grab()
	
	# Grab timer + break_surface
	for collider_id in grab_timers.keys():
		var collider = instance_from_id(collider_id)
		if collider and collider.is_in_group("Breakable"):  # Ensure the collider is valid
			grab_timers[collider_id] += delta
			
			# Check if the warning sound should play
			if grab_timers[collider_id] >= BREAK_TIME - WARNING_TIME and not warning_sound_played.get(collider_id, false):
				play_gravel_warning_sound(collider)
				warning_sound_played[collider_id] = true  # Mark that the warning sound has been played
			
			# Check if the surface should break
			if grab_timers[collider_id] >= BREAK_TIME:
				break_surface(collider)
				grab_timers.erase(collider_id)
				warning_sound_played.erase(collider_id)  # Remove the warning flag
		else:
			# If the collider is invalid, remove it from the dictionaries
			grab_timers.erase(collider_id)
			warning_sound_played.erase(collider_id)
	
	# Breakable respawn
	for collider_id in broken_surfaces.keys():
		broken_surfaces[collider_id] -= delta
		if broken_surfaces[collider_id] <= 0:
			respawn_surface(collider_id)
	
	# Game manager updates
	GameManager.update_player_position(global_transform.origin)
	var camera_rotation = $Head.global_transform.basis
	GameManager.update_player_position(global_transform.origin)
	GameManager.update_player_rotation(camera_rotation)
	
	# More noclip
	if noclip_enabled:
		handle_noclip(delta)
	elif left_hand_grabbing or right_hand_grabbing:
		handle_climbing(delta)
	else:
		handle_movement(delta)
	
	update_hands(delta)
	update_hand_rotations(delta) 
	move_and_slide()
	
	
	# Landing 
	if was_in_air and is_on_floor():
		emit_landing_particles()
		if is_falling:
			is_falling = false
			fall_time = 0.0
			wind_woosh_sound.stop()
			
			# Play landing sound
			if landing_sounds.size() > 0:
				var random_index = randi() % landing_sounds.size()
				# Ensure the same sound isn't played twice in a row
				while random_index == last_landing_sound_index:
					random_index = randi() % landing_sounds.size()
				last_landing_sound_index = random_index

				# Set random pitch and volume
				var pitch = randf_range(1.0, 1.2)  # Random pitch between 0.9 and 1.1
				var volume_db = -25  # Adjust volume as needed

				# Play the sound
				landing_sound.stream = landing_sounds[random_index]
				landing_sound.volume_db = volume_db
				landing_sound.pitch_scale = pitch
				landing_sound.play()
	was_in_air = !is_on_floor()
	
	# Falling effects
	if !is_on_floor() and velocity.y < 0:
		if !left_hand_grabbing and !right_hand_grabbing:
			fall_time += delta  # Increment fall time
			
			if fall_time >= MIN_FALL_TIME:
				if !is_falling:
					# Start falling effects
					is_falling = true
					if wind_woosh_sounds.size() > 0:
						var random_index = randi() % wind_woosh_sounds.size()
						wind_woosh_sound.stream = wind_woosh_sounds[random_index]
						wind_woosh_sound.volume_db = -20
						wind_woosh_sound.pitch_scale = randf_range(0.9, 1.1)
						wind_woosh_sound.play()
				
				# Update falling effects (camera shake)
				var shake_intensity = FALL_SHAKE_INTENSITY * (fall_time - MIN_FALL_TIME)
				var shake_offset = Vector3(
					randf_range(-shake_intensity, shake_intensity),
					randf_range(-shake_intensity, shake_intensity),
					0
				)
				camera.transform.origin = camera.transform.origin.lerp(shake_offset, delta * FALL_SHAKE_SPEED)
	else:
		if is_falling:
			# Stop falling effects when not falling
			is_falling = false
			fall_time = 0.0
			wind_woosh_sound.stop()

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
		
		# Movement input
		var input_dir = Input.get_vector("left", "right", "up", "down")
		var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var speed = SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
		
		# Lerp for movement
		if direction:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
	
	# Sprint (should remove probs)
	var speed = SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Crouch
	if Input.is_action_pressed("crouch"):
		speed *= 0.6
	
	if direction:
		if is_on_floor():
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 12.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 12.0)
	else:
		velocity.x = lerp(velocity.x, 0.0, delta * 10.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 10.0)

func handle_climbing(delta):
	velocity.y -= gravity * delta
	
	# Reset force tracking each frame
	left_hand_pull_force = Vector3.ZERO
	right_hand_pull_force = Vector3.ZERO
	left_hand_torque = 0.0
	right_hand_torque = 0.0
	
	if left_hand_grabbing or right_hand_grabbing:
		# Apply velocity decay only if the player is falling and has been falling for a certain duration
		if is_falling and fall_time >= MIN_FALL_TIME:
			velocity.y *= exp(-velocity_decay_rate * delta)  # Exponential decay
		
		# Input + cam orientation
		var input_dir = Input.get_vector("left", "right", "up", "down")
		var cam_basis = camera.global_transform.basis
		
		# Movement based on cam direction
		var move_direction = Vector3.ZERO
		move_direction += cam_basis.x * input_dir.x   
		move_direction += cam_basis.z * input_dir.y  
		move_direction = move_direction.normalized()
		
		# Climb speed
		var climb_speed = 5.0
		
		# Apply movement
		if left_hand_grabbing or right_hand_grabbing:
			velocity += move_direction * climb_speed * delta
			
			var pull_force = Vector3.ZERO
			
			if left_hand_grabbing:
				var collider = get_node(grab_joint_left.node_b) if grab_joint_left.node_b != NodePath("") else null
				if collider and collider.visible: 
					var dir_to_grab = (grab_point_left - global_position).normalized()
					var distance_to_grab = global_position.distance_to(grab_point_left)
					if distance_to_grab > MAX_GRAB_DISTANCE:
						var overreach = distance_to_grab - MAX_GRAB_DISTANCE
						global_position += dir_to_grab * overreach
						distance_to_grab = MAX_GRAB_DISTANCE
					if distance_to_grab > reach_distance:
						var current_pull = dir_to_grab * (distance_to_grab - reach_distance) * climb_force
						pull_force += current_pull
						left_hand_pull_force = current_pull  # Track the force
						left_hand_torque = current_pull.length() * distance_to_grab  # Simple torque approximation
			
			if right_hand_grabbing:
				var collider = get_node(grab_joint_right.node_b) if grab_joint_right.node_b != NodePath("") else null
				if collider and collider.visible:  
					var dir_to_grab = (grab_point_right - global_position).normalized()
					var distance_to_grab = global_position.distance_to(grab_point_right)
					if distance_to_grab > MAX_GRAB_DISTANCE:
						var overreach = distance_to_grab - MAX_GRAB_DISTANCE
						global_position += dir_to_grab * overreach
						distance_to_grab = MAX_GRAB_DISTANCE
					if distance_to_grab > reach_distance:
						var current_pull = dir_to_grab * (distance_to_grab - reach_distance) * climb_force
						pull_force += current_pull
						right_hand_pull_force = current_pull  # Track the force
						right_hand_torque = current_pull.length() * distance_to_grab  # Simple torque approximation
			
			velocity += pull_force * delta
			
			# Check for wood breaking
			check_wood_break()
			
func check_wood_break():
	# Check left hand
	if left_hand_grabbing:
		var collider = get_node(grab_joint_left.node_b) if grab_joint_left.node_b != NodePath("") else null
		if collider and collider.is_in_group("Wood"):
			# Check if force exceeds threshold
			if left_hand_pull_force.length() > WOOD_BREAK_FORCE or left_hand_torque > WOOD_BREAK_TORQUE:
				break_wood(collider, true)
	
	# Check right hand
	if right_hand_grabbing:
		var collider = get_node(grab_joint_right.node_b) if grab_joint_right.node_b != NodePath("") else null
		if collider and collider.is_in_group("Wood"):
			# Check if force exceeds threshold
			if right_hand_pull_force.length() > WOOD_BREAK_FORCE or right_hand_torque > WOOD_BREAK_TORQUE:
				break_wood(collider, false)
				
func break_wood(collider: Node, is_left_hand: bool):
	print("WOOD HAS BROKEN FROM PULL")
	
	# Play wood-specific breaking sound with randomization
	if wood_break_sounds.size() > 0:
		var random_index = randi() % wood_break_sounds.size()
		# Ensure we don't play the same sound twice in a row
		while random_index == last_grab_sound_index:
			random_index = randi() % wood_break_sounds.size()
		last_grab_sound_index = random_index
		
		# Set random pitch and volume
		var pitch = randf_range(0.8, 1.2)  # Slightly wider range for wood sounds
		var volume_db = -15  # Adjust volume as needed
		
		# Play the sound
		wood_break_sound.stream = wood_break_sounds[random_index]
		wood_break_sound.pitch_scale = pitch
		wood_break_sound.volume_db = volume_db
		wood_break_sound.global_position = collider.global_transform.origin
		wood_break_sound.play()
	
	# Hide and disable collision
	collider.visible = false
	collider.set_collision_layer_value(LAYER_WORLD, false)
	
	# Release the grab
	release_grab(is_left_hand)
	
	# Add some visual effects
	particles_hand(collider.global_transform.origin)
	
	# Apply a small force to the player in the opposite direction
	var break_force = left_hand_pull_force if is_left_hand else right_hand_pull_force
	velocity += -break_force.normalized() * 2.0  # Small recoil
	
	# Schedule respawn if needed
	var collider_id = collider.get_instance_id()
	broken_surfaces[collider_id] = RESPAWN_TIME

func check_grab():
	# Left hand grab logic
	if left_hand_reaching and not left_hand_grabbing and left_hand_cooldown <= 0:
		if left_hand_raycast.is_colliding():
			var collider = left_hand_raycast.get_collider()
			# Group check
			if collider and collider.is_in_group("Climbable"):
				var grab_point = left_hand_raycast.get_collision_point()
				var distance_to_grab = global_position.distance_to(grab_point)
				# Grab if in range
				if distance_to_grab <= MAX_GRAB_DISTANCE:
					grab_object(left_hand_raycast, true)
					hand_animation_player_left.play("close")
					
					# Grab sound + fx
					particles_hand(grab_point)
					# grab_sound.play()

	# Right hand grab logic
	if right_hand_reaching and not right_hand_grabbing and right_hand_cooldown <= 0:
		if right_hand_raycast.is_colliding():
			var collider = right_hand_raycast.get_collider()
			# Group check
			if collider and collider.is_in_group("Climbable"):
				var grab_point = right_hand_raycast.get_collision_point()
				var distance_to_grab = global_position.distance_to(grab_point)
				# Grab if in range
				if distance_to_grab <= MAX_GRAB_DISTANCE:
					grab_object(right_hand_raycast, false)
					hand_animation_player_right.play("close")
					
					# Grab sound + fx
					particles_hand(grab_point)
					# grab_sound.play()

func grab_object(hand_raycast: RayCast3D, is_left_hand: bool):
	
	is_falling = false
	fall_time = 0.0
	wind_woosh_sound.stop()
	
	# Connect joint to raycast
	if hand_raycast.is_colliding():
		var grab_point = hand_raycast.get_collision_point()
		var grab_joint = grab_joint_left if is_left_hand else grab_joint_right
		var collider = hand_raycast.get_collider()

		grab_joint.global_transform.origin = grab_point

		# NodeA is player
		grab_joint.node_a = self.get_path() 
		# Collision is nodeB
		grab_joint.node_b = collider.get_path()
		
		configure_hinge_joint(grab_joint)
	
		if is_left_hand:
			grab_point_left = grab_point
			left_hand_grabbing = true
			left_hand_rotation_locked = true
		else:
			grab_point_right = grab_point
			right_hand_grabbing = true
			right_hand_rotation_locked = true
		
		velocity.y *= 0.1  # Preserve some initial momentum (adjust as needed)
		
		# Track grab time by surface, not by hand
		var collider_id = collider.get_instance_id()
		if not grab_timers.has(collider_id):
			grab_timers[collider_id] = 0.0  # Only start a new timer if the surface isn't already being tracked
	
		# Random sound
		if grab_sounds.size() > 0:
			var random_index = randi() % grab_sounds.size()
			# Don't play same sound twice
			while random_index == last_grab_sound_index:
				random_index = randi() % grab_sounds.size()
			last_grab_sound_index = random_index

			# Random pitch
			if is_left_hand:
				left_hand_sound.volume_db = -20
				left_hand_sound.pitch_scale = randf_range(0.9, 1.1) 
				left_hand_sound.stream = grab_sounds[random_index]
				left_hand_sound.play()
			
			else:
				right_hand_sound.volume_db = -20
				right_hand_sound.pitch_scale = randf_range(0.9, 1.1)
				right_hand_sound.stream = grab_sounds[random_index]
				right_hand_sound.play()
	
		# Debugs
		print("GRABBED WITH", "left" if is_left_hand else "right", "hand at:", grab_point)
		print("NODE A:", grab_joint.node_a)
		print("NODE B:", grab_joint.node_b)

func release_grab(is_left_hand: bool):
	var grab_joint = grab_joint_left if is_left_hand else grab_joint_right
	var collider_path = grab_joint.node_b 
	
	if collider_path and collider_path != NodePath(""):
		var collider = get_node(collider_path)
		if collider:
			var collider_id = collider.get_instance_id()
			
			# Only remove the timer if both hands have released the surface
			if collider_id in grab_timers:
				if (is_left_hand and !right_hand_grabbing) or (!is_left_hand and !left_hand_grabbing):
					grab_timers.erase(collider_id)
					warning_sound_played.erase(collider_id)  # Also reset the warning flag
	
	# Disable joint
	grab_joint.node_b = NodePath("")

	if is_left_hand:
		left_hand_grabbing = false
		left_hand_rotation_locked = false  # Unlock left hand rotation
	else:
		right_hand_grabbing = false
		right_hand_rotation_locked = false  # Unlock right hand rotation
	print("Released", "left" if is_left_hand else "right", "hand")

func break_surface(collider: Node):
	if collider:
		print("Surface broke: ", collider.name)
		
		# Play rock break sound
		rock_break_sound.volume_db = -20
		if rock_break_sound and rock_break_sounds.size() > 0:
			var random_index = randi() % rock_break_sounds.size()
			rock_break_sound.stream = rock_break_sounds[random_index]
			rock_break_sound.pitch_scale = randf_range(0.9, 1.1)
			rock_break_sound.global_transform.origin = collider.global_transform.origin
			rock_break_sound.play()
		
		# Hide + no collision
		collider.visible = false
		collider.set_collision_layer_value(LAYER_WORLD, false)
		
		# Release both hands if they are grabbing the broken surface
		if left_hand_grabbing and grab_joint_left.node_b == collider.get_path():
			release_grab(true)  # Release left hand
		if right_hand_grabbing and grab_joint_right.node_b == collider.get_path():
			release_grab(false)  # Release right hand
		
		# Clean up dictionaries
		var collider_id = collider.get_instance_id()
		if grab_timers.has(collider_id):
			grab_timers.erase(collider_id)
		if warning_sound_played.has(collider_id):
			warning_sound_played.erase(collider_id)
		
		# Timer for respawn
		broken_surfaces[collider_id] = RESPAWN_TIME

func respawn_surface(collider_id: int):
	var collider = instance_from_id(collider_id)
	if collider:
		print("Surface respawned: ", collider.name)
		# Restore state
		collider.visible = true
		collider.set_collision_layer_value(LAYER_WORLD, true)
		broken_surfaces.erase(collider_id)
		warning_sound_played.erase(collider_id)  # Reset the warning flag

func update_hands(delta):
	var cam_basis = camera.global_transform.basis
	
	# Left hand position
	var left_target = grab_point_left if left_hand_grabbing else \
		camera.global_position + cam_basis * left_hand_initial_offset + \
		(-cam_basis.z * reach_distance if left_hand_reaching else Vector3.ZERO)
	
	# Right hand position
	var right_target = grab_point_right if right_hand_grabbing else \
		camera.global_position + cam_basis * right_hand_initial_offset + \
		(-cam_basis.z * reach_distance if right_hand_reaching else Vector3.ZERO)
	
	# Move hands to target positions with collision handling
	update_hand_position(left_hand, left_target, delta)
	update_hand_position(right_hand, right_target, delta)

func update_hand_position(hand: RigidBody3D, target: Vector3, delta: float):
	# Calculate movement direction and distance
	var movement = target - hand.global_position
	var movement_direction = movement.normalized()
	var movement_distance = movement.length()
	
	# Move_and_collide
	var collision = hand.move_and_collide(movement_direction * movement_distance * delta * hand_smoothing)
	
	if collision:
		var adjusted_target = hand.global_position + movement_direction * collision.get_remainder().length()
		hand.global_position = hand.global_position.lerp(adjusted_target, delta * hand_smoothing)
	else:
		hand.global_position = hand.global_position.lerp(target, delta * hand_smoothing)

func update_hand_rotations(delta):
	var cam_basis = camera.global_transform.basis
	
	# Left hand rotation
	if not left_hand_rotation_locked:
		var left_adjustment = Basis().rotated(Vector3.FORWARD, deg_to_rad(180))
		if left_hand_grabbing:
			var grab_dir = (grab_point_left - camera.global_position).normalized()
			var target_basis = Basis.looking_at(grab_dir, Vector3.UP)
			left_hand.global_transform.basis = left_hand.global_transform.basis.slerp(target_basis, delta * hand_smoothing)
		else:
			left_hand.global_transform.basis = left_hand.global_transform.basis.slerp(cam_basis * left_adjustment, delta * hand_smoothing)
	
	# Right hand rotation
	if not right_hand_rotation_locked:
		var right_adjustment = Basis().rotated(Vector3.FORWARD, deg_to_rad(180))
		if right_hand_grabbing:
			var grab_dir = (grab_point_right - camera.global_position).normalized()
			var target_basis = Basis.looking_at(grab_dir, Vector3.UP)
			right_hand.global_transform.basis = right_hand.global_transform.basis.slerp(target_basis, delta * hand_smoothing)
		else:
			right_hand.global_transform.basis = right_hand.global_transform.basis.slerp(cam_basis * right_adjustment, delta * hand_smoothing)

func particles_hand(contact_point):
	hand_fx.global_position = contact_point
	hand_fx.emitting = true

func play_gravel_warning_sound(collider: Node):
	if gravel_warning_sounds.size() > 0:
		var random_index = randi() % gravel_warning_sounds.size()
		var pitch = randf_range(0.9, 1.1)  
		var volume_db = -15
		gravel_warning_sound.stream = gravel_warning_sounds[random_index]
		gravel_warning_sound.pitch_scale = pitch
		gravel_warning_sound.volume_db = volume_db
		gravel_warning_sound.global_transform.origin = collider.global_transform.origin
		gravel_warning_sound.play()

func _on_area_3d_body_entered(body):
	print("Area3D entered by:", body.name)  # Debug: Check which body entered the area
	if body == self:  # Check if the player entered the area
		spawn_rock()

func check_area_collision():
	if area_3d and area_3d.overlaps_body(self):
		if not rock_instance:  # Spawn rock only if it doesn't already exist
			spawn_rock()

func spawn_rock():
	if rock_instance:  # Don't spawn a new rock if one already exists
		print("Rock already exists.")
		return
	
	if not rock_scene:
		print("Rock scene is not assigned!")
		return
	
	# Instantiate the rock scene
	var rock_node = rock_scene.instantiate()
	
	# Find the RigidBody3D child node
	var rigid_body = rock_node.find_child("RigidBody3D")  # Replace "RigidBody3D" with the actual name of your RigidBody3D node
	if rigid_body is RigidBody3D:
		rock_instance = rigid_body  # Assign the RigidBody3D to rock_instance
		get_parent().add_child(rock_node)  # Add the entire rock scene to the parent
		print("Rock spawned at:", rock_spawn_position)
		
		# Set the rock's initial position
		rock_instance.global_position = rock_spawn_position
		
		# Apply initial velocity to make the rock fall slower
		rock_instance.linear_velocity = Vector3(0, -2, 0)  # Reduced y velocity
		
		# Reduce the effect of gravity on the rock
		rock_instance.gravity_scale = 0.5  # Half the gravity effect
		
		# Connect to the rock's tree_exited signal to reset the rock instance
		rock_instance.connect("tree_exited", Callable(self, "_on_rock_destroyed"))
		
		# Mark the rock as spawned
		print("Rock spawned for the first time.")  # Debug: Confirm rock spawning
		
		# Play the rockfall sound with pitch variance
		if rockfall_sound:
			var pitch = randf_range(0.9, 1.1)  # Random pitch between 0.9 and 1.1
			var volume_db = -35  # Adjust volume as needed
			rockfall_sound.pitch_scale = pitch
			rockfall_sound.volume_db = volume_db
			rockfall_sound.play()

func _on_rock_destroyed():
	rock_instance = null  # Reset the rock instance
	print("Rock destroyed.")  # Debug: Check if the rock is destroyed
