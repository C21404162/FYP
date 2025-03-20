extends RigidBody3D

@export var lifetime: float = 5.0  # Time before rock despawns
var timer: float = 0.0


func _ready():
	# Randomize initial rotation for variety
	angular_velocity = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
	

func _process(delta):
	timer += delta
	if timer >= lifetime:
		queue_free()  # Remove rock after its lifetime expires

func _on_body_entered(body: Node):
	print("Rock collided with:", body.name)  # Debug: Check what the rock collided with
