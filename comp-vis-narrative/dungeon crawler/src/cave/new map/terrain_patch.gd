@tool
extends StaticBody3D
class_name TerrainPatch


enum Transition { NONE, NORTH, EAST, SOUTH, WEST }


var terrain_generator: TerrainGenerator
var x_idx: int
var z_idx: int

var subdivisions: int
var size: Vector3
var diagonal_type: TerrainGenerator.DiagonalType
var material : Material
var transition : Transition
var iterations : int

var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var concave_polygon: ConcavePolygonShape3D

var vertex_array_2d = []
var uv_array_2d = []
var normal_array_2d = []


func initialize(terrain_generator: TerrainGenerator, x_idx: int, z_idx: int,
	subdivisions: int, size: Vector3, diagonal_type: TerrainGenerator.DiagonalType,
	material : Material, transition : Transition):
	
	self.terrain_generator = terrain_generator
	self.x_idx = x_idx
	self.z_idx = z_idx
	
	self.subdivisions = subdivisions
	self.size = size
	self.diagonal_type = diagonal_type
	self.material = material
	self.transition = transition
	
	self.iterations = 2 ** subdivisions + 1


func update_material(material: Material) -> void:
	self.material = material
	mesh_instance.mesh.surface_set_material(0, material)


func generate_mesh() -> void:
	print("Started generating patch with ", subdivisions, " subdivision", "." if subdivisions == 1 else "s.")
	var start_time := Time.get_unix_time_from_system()
	
	var children = get_children()
	for child in children:
		child.queue_free()
	
	mesh_instance = MeshInstance3D.new()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	collision_shape = CollisionShape3D.new()
	add_child(mesh_instance)
	add_child(collision_shape)
	if Engine.is_editor_hint() && is_inside_tree():
		mesh_instance.set_owner(get_tree().get_edited_scene_root())
		collision_shape.set_owner(get_tree().get_edited_scene_root())
	
	mesh_instance.mesh = ArrayMesh.new()
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)

	# PackedVector**Arrays for mesh construction.
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	# Mesh Generation
	var initial := Vector3(-size.x / 2, 0, -size.z / 2) + global_position
	var cell_size := Vector3(size.x / (iterations - 1), size.y, size.z / (iterations - 1))
	
	var x_min = 1 if transition == Transition.WEST  else 0
	var z_min = 1 if transition == Transition.NORTH else 0
	var x_max = iterations - (1 if transition == Transition.EAST  else 0)
	var z_max = iterations - (1 if transition == Transition.SOUTH else 0)
	
	for z_index in iterations:
		vertex_array_2d.append([])
		uv_array_2d.append([])
		normal_array_2d.append([])
		for x_index in iterations:
			var x := initial.x + x_index * cell_size.x
			var z := initial.z + z_index * cell_size.z
			var y := terrain_generator.heightmap(x, z)
			
			verts.append(Vector3(x, y, z) - global_position)
			uvs.append(Vector2(float(x_index) / (iterations - 1), float(z_index) / (iterations - 1)))
			normals.append((terrain_generator.pos_from_map(x, z + cell_size.z) -
							terrain_generator.pos_from_map(x, z - cell_size.z)).cross(
							terrain_generator.pos_from_map(x + cell_size.x, z) -
							terrain_generator.pos_from_map(x - cell_size.x, z)).normalized())
			
			vertex_array_2d[z_index].append(verts[-1])
			uv_array_2d[z_index].append(uvs[-1])
			normal_array_2d[z_index].append(normals[-1])
			
			if x_index > x_min && x_index < x_max && z_index > z_min && z_index < z_max:
				var vertex_index := z_index * iterations + x_index
				var primary_diagonal := false
				match diagonal_type:
					TerrainGenerator.DiagonalType.SIMPLE:
						primary_diagonal = true
					TerrainGenerator.DiagonalType.ALTERNATING:
						primary_diagonal = (x_index + z_index) % 2 == 0
					TerrainGenerator.DiagonalType.SMOOTHING:
						primary_diagonal = (abs(terrain_generator.heightmap(x, z) -
												terrain_generator.heightmap(x - cell_size.x, z - cell_size.z)) >
											abs(terrain_generator.heightmap(x - cell_size.x, z) -
												terrain_generator.heightmap(x, z - cell_size.z)))
				
				if primary_diagonal:
					indices.append_array(PackedInt32Array([
						vertex_index - iterations - 1, vertex_index - iterations, vertex_index - 1,
						vertex_index - iterations, vertex_index, vertex_index - 1
					]))
				else:
					indices.append_array(PackedInt32Array([
						vertex_index - iterations - 1, vertex_index - iterations, vertex_index,
						vertex_index - iterations - 1, vertex_index, vertex_index - 1
					]))
	
	# Generate transition ramp
	var ramp_idx = iterations ** 2
	match transition:
		Transition.NORTH:
			var other : TerrainPatch = terrain_generator.patches[z_idx - 1][x_idx]
			for x in other.iterations:
				verts.append(other.vertex_array_2d[-1][x] + other.global_position - global_position)
				uvs.append(Vector2(other.uv_array_2d[-1][x].x, 1 - other.uv_array_2d[-1][x].y))
				normals.append(other.normal_array_2d[-1][x])
				
				if x % 2 == 0 && x > 0:
					indices.append_array(PackedInt32Array([
						ramp_idx + x - 2, ramp_idx + x - 1,   iterations + x / 2 - 1,
						ramp_idx + x - 1, ramp_idx + x,	  	  iterations + x / 2,
						ramp_idx + x - 1, iterations + x / 2, iterations + x / 2 - 1
					]))
		Transition.SOUTH:
			var other : TerrainPatch = terrain_generator.patches[z_idx + 1][x_idx]
			for x in other.iterations:
				verts.append(other.vertex_array_2d[0][x] + other.global_position - global_position)
				uvs.append(Vector2(other.uv_array_2d[0][x].x, 1 - other.uv_array_2d[0][x].y))
				normals.append(other.normal_array_2d[0][x])
				
				var connect = iterations * (iterations - 2)
				
				if x % 2 == 0 && x > 0:
					indices.append_array(PackedInt32Array([
						ramp_idx + x - 1, ramp_idx + x - 2,	   connect + x / 2 - 1,
						ramp_idx + x,	  ramp_idx + x - 1,	   connect + x / 2,
						ramp_idx + x - 1, connect + x / 2 - 1, connect + x / 2
					]))
		Transition.WEST:
			var other : TerrainPatch = terrain_generator.patches[z_idx][x_idx - 1]
			for z in other.iterations:
				verts.append(other.vertex_array_2d[z][-1] + other.global_position - global_position)
				uvs.append(Vector2(1 - other.uv_array_2d[z][-1].x, other.uv_array_2d[z][-1].y))
				normals.append(other.normal_array_2d[z][-1])
				
				if z % 2 == 0 && z > 0:
					indices.append_array(PackedInt32Array([
						ramp_idx + z - 1, ramp_idx + z - 2, 			iterations * (z / 2 - 1) + 1,
						ramp_idx + z,	  ramp_idx + z - 1, 			iterations * (z / 2) + 1,
						ramp_idx + z - 1, iterations * (z / 2 - 1) + 1, iterations * (z / 2) + 1
					]))
		Transition.EAST:
			var other : TerrainPatch = terrain_generator.patches[z_idx][x_idx + 1]
			for z in other.iterations:
				verts.append(other.vertex_array_2d[z][0] + other.global_position - global_position)
				uvs.append(Vector2(1 - other.uv_array_2d[z][0].x, other.uv_array_2d[z][0].y))
				normals.append(other.normal_array_2d[z][0])
				
				var connect = iterations - 2
				
				if z % 2 == 0 && z > 0:
					indices.append_array(PackedInt32Array([
						ramp_idx + z - 2, ramp_idx + z - 1,				  connect + iterations * (z / 2 - 1),
						ramp_idx + z - 1, ramp_idx + z,	  				  connect + iterations * (z / 2),
						ramp_idx + z - 1, connect + iterations * (z / 2), connect + iterations * (z / 2 - 1)
					]))
	
	# Print number of vertices and triangles
	print("Generated patch geometry with ", verts.size(), " vertices and ", indices.size() / 3, " triangles.")

	# Assign arrays to surface array.
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices

	# Create mesh surface from mesh array.
	# No blendshapes, lods, or compression used.
	mesh_instance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	mesh_instance.mesh.surface_set_material(0, material)
	
	# Create Packed Vector 3 Array of faces for Concave Polygon 3D 
	var faces := PackedVector3Array()
	# Iterate through each index in the indices array
	for index in indices: # Append the vertex corresponding to each index
		faces.append(verts[index])
	
	# Create the Concave Polygon
	concave_polygon = ConcavePolygonShape3D.new()
	# Set the faces array of the Concave Polygon
	concave_polygon.set_faces(faces)
	# Set the Collision Shape to the Concave Polygon
	collision_shape.shape = concave_polygon;
	
	var duration := Time.get_unix_time_from_system() - start_time;
	print("Completed patch in ", "%0.3f" % duration, " seconds.\n")
