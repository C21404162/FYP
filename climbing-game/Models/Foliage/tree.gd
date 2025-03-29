extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Get your imported tree
	var tree = $"."

# Apply triplanar to all materials
	for child in tree.find_children("*", "MeshInstance3D"):
		var mat = child.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.uv1_triplanar = true
			mat.uv1_triplanar_sharpness = 1.0  # Adjust as needed


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
