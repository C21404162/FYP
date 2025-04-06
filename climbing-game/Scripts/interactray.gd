extends RayCast3D#

@onready var interaction_icon: TextureRect = $"../../../../Fade_interact/interaction_icon"
@onready var dialogue_label: Label = $"../../../../Dialogue/Panel/dialogue_label"
@onready var dialogue_panel: Panel = $"../../../../Dialogue/Panel"

@onready var player: CharacterBody3D = $"../../.."

const DialogueResource = preload("res://dialogue_resource.gd")

var current_dialogue: DialogueResource
var current_line = 0
var is_dialogue_active = false
var is_processing_interaction = false
var is_advancing_dialogue = false
var is_animating_text = false  
var skip_animation = false 
var cooldown = false

func _ready() -> void:
	#transparent
	create_tween().tween_property(interaction_icon, "modulate", Color(1, 1, 1, 0), 0.1)
	dialogue_panel.visible = false  

func _process(delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		#group check
		if collider and collider.is_in_group("Interactable"):
			#make icon fade in
			create_tween().tween_property(interaction_icon, "modulate", Color(1, 1, 1, 1), 0.1)
		
			#interacting
			if Input.is_action_just_pressed("interact"):
				if not is_dialogue_active and not cooldown: 
					is_processing_interaction = true
					var dialogue_path = "res://Dialogue/%s_dialogue.tres" % collider.name
					print("INTERACTED")
			
					print("PATH USED: ", dialogue_path)
					if ResourceLoader.exists(dialogue_path):
						current_dialogue = load(dialogue_path)
						print("DIALOGUE LOADED: ", current_dialogue)
						start_dialogue()
					else:
						print("DIALOGUE NOT FOUND HERE: ", dialogue_path)
						#spam stopper
					await get_tree().create_timer(0.2).timeout
					is_processing_interaction = false
		else:
			create_tween().tween_property(interaction_icon, "modulate", Color(1, 1, 1, 0), 0.1)
			dialogue_panel.visible = false
	else:
		create_tween().tween_property(interaction_icon, "modulate", Color(1, 1, 1, 0), 0.1)
		dialogue_panel.visible = false
	
	if is_dialogue_active:
		if Input.is_action_just_pressed("interact") and not is_advancing_dialogue: 
			if is_animating_text:
				skip_animation = true  
			else:
				is_advancing_dialogue = true
				print("INTERACTED_CONT")
				next_line()
				await get_tree().create_timer(0.2).timeout
				is_advancing_dialogue = false

func start_dialogue() -> void:
	if current_dialogue and current_dialogue.dialogue_lines.size() > 0:
		current_line = 0
		is_dialogue_active = true
		dialogue_panel.visible = true
		show_dialogue_line()
		#if player and player.has_method("set_can_move"):
			#player.set_can_move(false)

func show_dialogue_line() -> void:
	if current_line < current_dialogue.dialogue_lines.size():
		var line = current_dialogue.dialogue_lines[current_line]
		print("SHOWINGLINE: ", line)
		dialogue_label.text = "" 
		dialogue_panel.visible = true
		is_animating_text = true  
		skip_animation = false 
		
		#typewriter animation thing
		var full_text = "%s: %s" % [line["speaker"], line["text"]]
		for i in range(full_text.length() + 1):
			if skip_animation: 
				dialogue_label.text = full_text
				break
			dialogue_label.text = full_text.substr(0, i)
			await get_tree().create_timer(0.05).timeout  
		
		is_animating_text = false  
	else:
		print("DIALOGUEEND")	
		end_dialogue()

func next_line() -> void:
	print("NEXTLINE")
	current_line += 1
	show_dialogue_line()

func end_dialogue() -> void:
	is_dialogue_active = false
	dialogue_panel.visible = false
	current_dialogue = null
	current_line = 0
	#if player and player.has_method("set_can_move"):
		#player.set_can_move(true)
	print("DIALOGUEENDFULLY")
