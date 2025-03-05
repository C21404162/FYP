extends MeshInstance3D

@export var width: int = 50  # Number of vertices along the X-axis
@export var depth: int = 50  # Number of vertices along the Z-axis
@export var noise_scale: float = 10.0  # Scale of the noise
@export var height_scale: float = 2.0  # Amplitude of the terrain height

var noise = FastNoiseLite.new()

func _ready():
	noise.seed = randi()  # Random seed for variation
	noise.frequency = 0.05  # Controls the smoothness of the noise
	generate_ground()

func generate_ground():
	var mesh = ArrayMesh.new()
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Generate vertices
	for x in range(width):
		for z in range(depth):
			var y = noise.get_noise_2d(x, z) * height_scale
			surface_tool.add_vertex(Vector3(x, y, z))

	# Generate indices for triangles
	for x in range(width - 1):
		for z in range(depth - 1):
			var i = x + z * width  # Current vertex index
			var i1 = i + 1  # Next vertex in the row
			var i2 = i + width  # Vertex directly below
			var i3 = i + width + 1  # Vertex below and to the right

			# First triangle (i, i1, i2)
			surface_tool.add_index(i)
			surface_tool.add_index(i1)
			surface_tool.add_index(i2)

			# Second triangle (i1, i3, i2)
			surface_tool.add_index(i1)
			surface_tool.add_index(i3)
			surface_tool.add_index(i2)

	# Generate normals and UVs
	surface_tool.generate_normals()
	surface_tool.generate_tangents()

	# Commit the mesh
	mesh = surface_tool.commit()

	# Assign the mesh to the MeshInstance3D
	self.mesh = mesh
