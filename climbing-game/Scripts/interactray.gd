extends RayCast3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	if is_colliding() and is_in_group("Interactable"):
		print("LOOK")
