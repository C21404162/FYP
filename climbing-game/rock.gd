extends RigidBody3D

@export var lifetime: float = 5.0  # Time before rock despawns
var timer: float = 0.0

# Custom signal to notify when the rock hits the player
signal hit_player(body: Node)

func _ready():
	# Randomize initial rotation for variety
	angular_velocity = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
	
	# Connect the body_entered signal to this script
	connect("body_entered", Callable(self, "_on_body_entered"))

func _process(delta):
	timer += delta
	if timer >= lifetime:
		queue_free()  # Remove rock after its lifetime expires

func _on_body_entered(body: Node):
	# Emit the custom signal when the rock collides with the player
	emit_signal("hit_player", body)
