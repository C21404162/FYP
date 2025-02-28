extends RayCast3D

@onready var interaction_icon: TextureRect = $"../../../../Fade_interact/interaction_icon"
@onready var dialogue_label: Label = $"../../../../Dialogue/Panel/dialogue_label"  # Reference to a Label for displaying text

func _ready() -> void:
	create_tween().tween_property(interaction_icon, "modulate", Color(1, 1, 1, 0), 0.1)
	dialogue_label.visible = false

func _process(delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		if collider and collider.is_in_group("Interactable"):
			# Show the interaction icon
			create_tween().tween_property(interaction_icon, "modulate", Color(1, 1, 1, 1), 0.1)

			# Check for interact input
			if Input.is_action_just_pressed("interact"):
				# Display text when interact is pressed
				dialogue_label.text = "You interacted with the object!"
				dialogue_label.visible = true
		else:
			# Hide the interaction icon
			create_tween().tween_property(interaction_icon, "modulate", Color(1, 1, 1, 0), 0.1)
			# Hide the dialogue label if not interacting with an interactable object
			dialogue_label.visible = false
	else:
		# Hide the interaction icon if the raycast isn't colliding
		create_tween().tween_property(interaction_icon, "modulate", Color(1, 1, 1, 0), 0.1)
		# Hide the dialogue label if the raycast isn't colliding
		dialogue_label.visible = false
