extends RigidBody3D

@export var lifetime: float = 5.0  #despawn time
var timer: float = 0.0


func _ready():
	#random rot
	angular_velocity = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
	

func _process(delta):
	timer += delta
	if timer >= lifetime:
		queue_free() 

func _on_body_entered(body: Node):
	print("Rock has hit:", body.name) 
