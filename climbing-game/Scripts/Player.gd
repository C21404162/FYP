extends CharacterBody3D

# Movement
const WALK_SPEED = 3.5
const SPRINT_SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.005
const MAX_JUMP_CHARGE_TIME = 1.0 
const MIN_CHARGE_FOR_BOOST = 0.3
const MAX_JUMP_BOOST = 1.5 
const MAX_GRAB_DISTANCE = 2.65 

# Collision layers
const LAYER_WORLD = 1
const LAYER_HANDS = 2
const LAYER_PLAYER = 4

# Physics stuff
@export var hand_smoothing = 40
@export var reach_distance = 0.6
@export var reach_speed = 12.5
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
#
var left_hand_rotation_locked = false
var right_hand_rotation_locked = false


#landing 
var was_in_air = false
@onready var landing_particles = $LandingParticles

#grabsounds
@export var grab_sounds: Array[AudioStream] = []
@onready var left_hand_sound = $lefthand/grab_sound_left
@onready var right_hand_sound = $righthand/grab_sound_right
var last_grab_sound_index = -1

# Gravity
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Pause menu
@export var pause_menu_scene_path: String = "res://pause.tscn"
var pause_menu_instance: Control = null

# Game manager
@onready var game_manager = get_node("/root/GameManager")

#Breaking
var grab_timers: Dictionary = {}  #track how long surface is held
var broken_surfaces: Dictionary = {}  #tracks timers+surfaces
const BREAK_TIME: float = 3.0  #time b4 break
const RESPAWN_TIME: float = 5.0  #respawn timer

# Sound effects
#@export var break_sound: AudioStream  # Sound to play when a surface breaks
#@export var respawn_sound: AudioStream  # Sound to play when a surface respawns

@onready var hand_animation_player = $lefthand/hand_left_rigged/AnimationPlayer

func _ready():
	

	#noise 4 falling
	
	## Configure left joint
	#configure_hinge_joint(grab_joint_left)
	#
	## Configure right joint
	#configure_hinge_joint(grab_joint_right)
	
	# Set FOV from GameManager
	camera.fov = GameManager.fov
	GameManager.connect("fov_updated", Callable(self, "_on_fov_updated"))
	
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
	setup_hands()
	left_hand_initial_offset = left_hand.global_position - camera.global_position
	right_hand_initial_offset = right_hand.global_position - camera.global_position
	setup_game_manager_connection()
	
	# Only spawn falling if no saved position exists
	if GameManager.player_position == Vector3.ZERO:
		spawn_falling()
	else:
		# Apply saved position and rotation
		global_transform.origin = GameManager.player_position
		$Head.global_transform.basis = GameManager.player_rotation

func configure_hinge_joint(joint: HingeJoint3D):
	# Enable angular limits
	joint.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	
	# Set angular limits
	joint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, -0.1)  # Slight lower limit
	joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, 0.1)  # Slight upper limit
	
	# Set bias and relaxation for stiffness
	joint.set_param(HingeJoint3D.PARAM_LIMIT_BIAS, 10)  # Increase bias for stiffness
	joint.set_param(HingeJoint3D.PARAM_LIMIT_RELAXATION, 0.1)  # Reduce relaxation
	
	print("Hinge joint lower limit:", joint.get_param(HingeJoint3D.PARAM_LIMIT_LOWER))
	print("Hinge joint upper limit:", joint.get_param(HingeJoint3D.PARAM_LIMIT_UPPER))
	print("Hinge joint bias:", joint.get_param(HingeJoint3D.PARAM_LIMIT_BIAS))
	print("Hinge joint relaxation:", joint.get_param(HingeJoint3D.PARAM_LIMIT_RELAXATION))
	
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
		game_manager.connect("player_position_updated", Callable(self, "_on_player_position_updated"))
		game_manager.connect("player_rotation_updated", Callable(self, "_on_player_rotation_updated"))
	else:
		print("*GAME MANAGER NOT FOUND")

#physics setup
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
	
	left_hand.mass = 1.0
	right_hand.mass = 1.0
	left_hand.inertia = Vector3(1, 1, 1)
	right_hand.inertia = Vector3(1, 1, 1)
	

func _unhandled_input(event):
	#pause
	if event.is_action_pressed("esc"):
		if pause_menu_instance:
			if pause_menu_instance.is_inside_tree():
				pause_menu_instance.toggle_pause()
	
	#mouse movement
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	#grab binds
	if event.is_action_pressed("grab_left"):
		hand_animation_player.play("open")
		left_hand_reaching = true
	elif event.is_action_released("grab_left"):
		hand_animation_player.play("default")
		left_hand_reaching = false
		release_grab(true)

	if event.is_action_pressed("grab_right"):
		right_hand_reaching = true
	elif event.is_action_released("grab_right"):
		right_hand_reaching = false
		release_grab(false)
				
	# Noclip toggle
	if event.is_action_pressed("noclip"):
		hand_animation_player.play("open")
		noclip_enabled = !noclip_enabled
		if noclip_enabled:
			collision_mask = 0 
		else:
			collision_mask = LAYER_WORLD

func _physics_process(delta):
	check_grab()
	
	#grab timer + break_surface
	for collider_id in grab_timers.keys():
		grab_timers[collider_id] += delta
		if grab_timers[collider_id] >= BREAK_TIME:
			var collider = instance_from_id(collider_id)
			if collider and collider.is_in_group("Breakable"):  # Check if the surface is in the "Breakable" group
				break_surface(collider)
				grab_timers.erase(collider_id)
				release_grab(left_hand_grabbing)
	
	#breakable respawn
	for collider_id in broken_surfaces.keys():
		broken_surfaces[collider_id] -= delta
		if broken_surfaces[collider_id] <= 0:
			respawn_surface(collider_id)
	
	#game manager updates
	GameManager.update_player_position(global_transform.origin)
	var camera_rotation = $Head.global_transform.basis
	GameManager.update_player_position(global_transform.origin)
	GameManager.update_player_rotation(camera_rotation)
	
	#more noclip
	if noclip_enabled:
		handle_noclip(delta)
	elif left_hand_grabbing or right_hand_grabbing:
		handle_climbing(delta)
	else:
		handle_movement(delta)
	
	update_hands(delta)
	move_and_slide()
	
	#landing 
	if !was_in_air and is_on_floor():
		emit_landing_particles()
	was_in_air = !is_on_floor()

#landing fx
func emit_landing_particles():
	if landing_particles:
		landing_particles.global_transform.origin = global_transform.origin
		landing_particles.emitting = true

#noclip
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
		
		#movement input
		var input_dir = Input.get_vector("left", "right", "up", "down")
		var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var speed = SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
		
		#lerp 4 movement
		if direction:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
	
	#sprint (should remove probs)
	var speed = SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	#crouch
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
	
	#input + cam orientation
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var cam_basis = camera.global_transform.basis
	
	#movement based on cam direction
	var move_direction = Vector3.ZERO
	move_direction += cam_basis.x * input_dir.x   
	move_direction += cam_basis.z * input_dir.y  
	move_direction = move_direction.normalized()
	
	#climb speed
	var climb_speed = 5.0
	
	# Apply movement
	if left_hand_grabbing or right_hand_grabbing:
		velocity += move_direction * climb_speed * delta
		
		var pull_force = Vector3.ZERO
		
		if left_hand_grabbing:
			var dir_to_grab = (grab_point_left - global_position).normalized()
			var distance_to_grab = global_position.distance_to(grab_point_left)
			if distance_to_grab > MAX_GRAB_DISTANCE:
				var overreach = distance_to_grab - MAX_GRAB_DISTANCE
				global_position += dir_to_grab * overreach
				distance_to_grab = MAX_GRAB_DISTANCE
			if distance_to_grab > reach_distance:
				pull_force += dir_to_grab * (distance_to_grab - reach_distance) * climb_force
		
		if right_hand_grabbing:
			var dir_to_grab = (grab_point_right - global_position).normalized()
			var distance_to_grab = global_position.distance_to(grab_point_right)
			if distance_to_grab > MAX_GRAB_DISTANCE:
				var overreach = distance_to_grab - MAX_GRAB_DISTANCE
				global_position += dir_to_grab * overreach
				distance_to_grab = MAX_GRAB_DISTANCE
			if distance_to_grab > reach_distance:
				pull_force += dir_to_grab * (distance_to_grab - reach_distance) * climb_force
		
		velocity += pull_force * delta

func check_grab():
	#left hand grab logic
	if left_hand_reaching and not left_hand_grabbing:
		if left_hand_raycast.is_colliding():
			var collider = left_hand_raycast.get_collider()
			#group check
			if collider and collider.is_in_group("Climbable"):
				var grab_point = left_hand_raycast.get_collision_point()
				var distance_to_grab = global_position.distance_to(grab_point)
				#grab if in range
				if distance_to_grab <= MAX_GRAB_DISTANCE:
					grab_object(left_hand_raycast, true)
					print("Left hand grabbed: ", collider.name)
					hand_animation_player.play("close")
					
					#grab sound + fx
					particles_hand(grab_point)
					#grab_sound.play()

	#right hand grab logic
	if right_hand_reaching and not right_hand_grabbing:
		if right_hand_raycast.is_colliding():
			var collider = right_hand_raycast.get_collider()
			#group check
			if collider and collider.is_in_group("Climbable"):
				var grab_point = right_hand_raycast.get_collision_point()
				var distance_to_grab = global_position.distance_to(grab_point)
				#grab if in range
				if distance_to_grab <= MAX_GRAB_DISTANCE:
					grab_object(right_hand_raycast, false)
					print("RIGHT HAND GRABBED: ", collider.name)
					
					#grab sound + fx
					particles_hand(grab_point)
					#grab_sound.play()

func grab_object(hand_raycast: RayCast3D, is_left_hand: bool):
	#connect joint 2 raycast
	if hand_raycast.is_colliding():
		var grab_point = hand_raycast.get_collision_point()
		var grab_joint = grab_joint_left if is_left_hand else grab_joint_right
		var collider = hand_raycast.get_collider()

		grab_joint.global_transform.origin = grab_point

		#nodeA is player
		grab_joint.node_a = self.get_path() 
		#collision is nodeB
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
		#track grgab time
		if not grab_timers.has(collider.get_instance_id()):
			grab_timers[collider.get_instance_id()] = 0.0
	
		#random sound
		if grab_sounds.size() > 0:
			var random_index = randi() % grab_sounds.size()
			#dont play same sound twice
			while random_index == last_grab_sound_index:
				random_index = randi() % grab_sounds.size()
			last_grab_sound_index = random_index

			#random pitch
			if is_left_hand:
				left_hand_sound.volume_db = -20
				left_hand_sound.pitch_scale = randf_range(0.9, 1.1) 
				left_hand_sound.stream = grab_sounds[random_index]
				left_hand_sound.play()
			
			else:
				right_hand_sound.volume_db =-20
				right_hand_sound.pitch_scale = randf_range(0.9, 1.1)
				right_hand_sound.stream = grab_sounds[random_index]
				right_hand_sound.play()
	
		#debugs
		print("GRABBED WITH", "left" if is_left_hand else "right", "hand at:", grab_point)
		print("NODE A:", grab_joint.node_a)
		print("NODE B:", grab_joint.node_b)

func release_grab(is_left_hand: bool):
	var grab_joint = grab_joint_left if is_left_hand else grab_joint_right
	var collider_path = grab_joint.node_b 
	
	if collider_path and collider_path != NodePath(""):
		var collider = get_node(collider_path)
		if collider and grab_timers.has(collider.get_instance_id()):
			grab_timers.erase(collider.get_instance_id())
	
	# Disable joint
	grab_joint.node_b = NodePath("")

	if is_left_hand:
		left_hand_grabbing = false
		left_hand_rotation_locked = false  # Unlock left hand rotation
	else:
		right_hand_grabbing = false
		right_hand_rotation_locked = false  # Unlock right hand rotation
		
	print("Released", "left" if is_left_hand else "right", "hand")

func break_surface(collider: Node,):
	if collider:
		print("Surface broke: ", collider.name)
		
		#hide+no collision
		collider.visible = false
		collider.set_collision_layer_value(LAYER_WORLD, false)
		#particles_hand(grab_point)
		#timer
		broken_surfaces[collider.get_instance_id()] = RESPAWN_TIME

func respawn_surface(collider_id: int):
	var collider = instance_from_id(collider_id)
	if collider:
		print("Surface respawned: ", collider.name)
		#restore state
		collider.visible = true
		collider.set_collision_layer_value(LAYER_WORLD, true)
		broken_surfaces.erase(collider_id)

func update_hands(delta):
	var cam_basis = camera.global_transform.basis
	
	#Left hand position
	var left_target = grab_point_left if left_hand_grabbing else \
		camera.global_position + cam_basis * left_hand_initial_offset + \
		(-cam_basis.z * reach_distance if left_hand_reaching else Vector3.ZERO)
	
	#Right hand position
	var right_target = grab_point_right if right_hand_grabbing else \
		camera.global_position + cam_basis * right_hand_initial_offset + \
		(-cam_basis.z * reach_distance if right_hand_reaching else Vector3.ZERO)
	
	#move hands to target pos
	left_hand.global_position = left_hand.global_position.lerp(
		left_target,
		delta * (reach_speed if left_hand_reaching else hand_smoothing))
	
	right_hand.global_position = right_hand.global_position.lerp(
		right_target,
		delta * (reach_speed if right_hand_reaching else hand_smoothing))
		
		
#update hands
func _process(delta):
	update_hand_rotations(delta)

func update_hand_rotations(delta):
	var cam_basis = camera.global_transform.basis
	
	# Left hand rotation
	if not left_hand_rotation_locked:
		var left_adjustment = Basis().rotated(Vector3.FORWARD, deg_to_rad(180))
		if left_hand_grabbing:
			var grab_dir = (grab_point_left - camera.global_position).normalized()
			var target_basis = Basis.looking_at(grab_dir, Vector3.UP)
			left_hand.global_transform.basis = left_hand.global_transform.basis.slerp(
				target_basis, 
				delta * hand_smoothing
			)
		else:
			left_hand.global_transform.basis = left_hand.global_transform.basis.slerp(
				cam_basis * left_adjustment,
				delta * hand_smoothing
			)
	
	# Right hand rotation
	if not right_hand_rotation_locked:
		var right_adjustment = Basis().rotated(Vector3.FORWARD, deg_to_rad(180))
		if right_hand_grabbing:
			var grab_dir = (grab_point_right - camera.global_position).normalized()
			var target_basis = Basis.looking_at(grab_dir, Vector3.UP)
			right_hand.global_transform.basis = right_hand.global_transform.basis.slerp(
				target_basis, 
				delta * hand_smoothing
			)
		else:
			right_hand.global_transform.basis = right_hand.global_transform.basis.slerp(
				cam_basis * right_adjustment,
				delta * hand_smoothing
			)

#hand fx
func particles_hand(contact_point):
	hand_fx.global_position = contact_point
	hand_fx.emitting = true
