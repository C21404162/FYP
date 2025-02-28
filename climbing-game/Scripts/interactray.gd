extends RayCast3D

@onready var interaction_icon: TextureRect = $"../../../../Fade_interact/interaction_icon"
@onready var dialogue_label: Label = $"../../../../Dialogue/Panel/dialogue_label"

func _ready() -> void:
	create_tween().tween_property(interaction_icon, "modulate", Color(1, 1, 1, 0), 0.1)
	dialogue_label.visible = false

func _process(delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		if collider and collider.is_in_group("Interactable"):
			create_tween().tween_property(interaction_icon, "modulate", Color(1, 1, 1, 1), 0.1)

			if Input.is_action_just_pressed("interact"):
				dialogue_label.text = "You interacted with the object!"
				dialogue_label.visible = true
		else:
			create_tween().tween_property(interaction_icon, "modulate", Color(1, 1, 1, 0), 0.1)
			dialogue_label.visible = false
	else:
		create_tween().tween_property(interaction_icon, "modulate", Color(1, 1, 1, 0), 0.1)
		dialogue_label.visible = false
