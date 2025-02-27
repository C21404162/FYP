extends RayCast3D

@export var interaction_icon: TextureRect  # Reference to the UI icon

func _ready() -> void:
	#interaction_icon.modulate = Color(1, 1, 1, 0)  # Hide the icon initially
	create_tween().tween_property(interaction_icon, "modulate", Color(1, 1, 1, 0), 0.1)

func _process(delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		if collider and collider.is_in_group("Interactable"):
			# Show the interaction icon
			create_tween().tween_property(interaction_icon, "modulate", Color(1, 1, 1, 0), 0.1)
		else:
			# Hide the interaction icon
			create_tween().tween_property(interaction_icon, "modulate", Color(1, 1, 1, 0), 0.1)
	else:
		# Hide the interaction icon if the raycast isn't colliding
		create_tween().tween_property(interaction_icon, "modulate", Color(1, 1, 1, 0), 0.1)
