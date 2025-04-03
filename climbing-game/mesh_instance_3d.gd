extends MeshInstance3D

@export var width: int = 50 
@export var depth: int = 50 
@export var noise_scale: float = 10.0  
@export var height_scale: float = 2.0 

var noise = FastNoiseLite.new()

func _ready():
	noise.seed = randi() 
	noise.frequency = 0.05 
	generate_ground()

func generate_ground():
	var mesh = ArrayMesh.new()
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	#Vertices
	for x in range(width):
		for z in range(depth):
			var y = noise.get_noise_2d(x, z) * height_scale
			surface_tool.add_vertex(Vector3(x, y, z))

	#indices
	for x in range(width - 1):
		for z in range(depth - 1):
			var i = x + z * width  
			var i1 = i + 1 
			var i2 = i + width  
			var i3 = i + width + 1  

			surface_tool.add_index(i)
			surface_tool.add_index(i1)
			surface_tool.add_index(i2)

			surface_tool.add_index(i1)
			surface_tool.add_index(i3)
			surface_tool.add_index(i2)

	#normals+UVS
	surface_tool.generate_normals()
	surface_tool.generate_tangents()
	mesh = surface_tool.commit()
	self.mesh = mesh
