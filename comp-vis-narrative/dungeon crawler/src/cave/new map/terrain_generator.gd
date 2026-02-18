@tool
extends Node3D
class_name TerrainGenerator

enum DetailMode {HIGH, MEDIUM, LOW, DISTANCE}
enum DiagonalType {SIMPLE, ALTERNATING, SMOOTHING}

@export_tool_button("Generate Terrain", "MainPlay") var generate_button = generate_mesh


@export_group("Chunks")


@export var chunk_size := Vector3(10, 1, 10) :
	set(value):
		if chunk_size != value:
			chunk_size = value
			update_size()


@export_range(1, 100) var edge_chunks := 1 :
	set(value):
		if edge_chunks != value:
			edge_chunks = value
			update_size()


@export_group("Random")


@export var seed := 0 :
	set(value):
		seed = value
		height_noise_a.set_noise_type(FastNoiseLite.TYPE_PERLIN)
		height_noise_a.set_seed(seed)
		height_noise_b.set_noise_type(FastNoiseLite.TYPE_PERLIN)
		height_noise_b.set_seed(seed + 1)
		height_noise_c.set_noise_type(FastNoiseLite.TYPE_PERLIN)
		height_noise_c.set_seed(seed + 2)
		
@export_tool_button("Randomize Seed", "Loop") var randomize = randomize_seed


@export_group("Noise")
@export var use_texture_a : bool :
	set(value):
		use_texture_a = value
		touch_noise()
var image_a
var image_a_width
var image_a_height
@export var texture_a : Texture2D :
	set(value):
		texture_a = value
		touch_noise()
@export var color_curve: Curve
@export_range(0.1, 20, 0.1) var density_a := 2.0 :
	set(value):
		density_a = value
		touch_noise()
@export_range(0.1, 50, 0.1) var height_a := 35.0 :
	set(value):
		height_a = value
		touch_noise()
@export_range(0.1, 20, 0.1) var density_b := 10.0 :
	set(value):
		density_b = value
		touch_noise()
@export_range(0.1, 50, 0.1) var height_b := 5.0 :
	set(value):
		height_b = value
		touch_noise()
@export_range(0.1, 20, 0.1) var density_c := 15.0 :
	set(value):
		density_c = value
		touch_noise()
@export_range(0.1, 50, 0.1) var height_c := 2.0 :
	set(value):
		height_c = value
		touch_noise()


@export_group("LOD")


@export var detail_mode := DetailMode.DISTANCE


@export_range(2, 8) var subdivisions := 6


@export var diagonal_type := DiagonalType.SMOOTHING


@export_group("Material")

# TODO tweak
@export var material : Material :#= preload("res://Materials/basic.tres") :
	set(value):
		if material != value:
			material = value
			if Engine.is_editor_hint():
				update_material()


var height_noise_a := FastNoiseLite.new()
var height_noise_b := FastNoiseLite.new()
var height_noise_c := FastNoiseLite.new()
var size := chunk_size * Vector3(edge_chunks, 1, edge_chunks)
var shape_changed = true

const PATCH = preload("res://dungeon crawler/src/cave/new map/terrain_patch.tscn")
var patches = []


func touch_noise() -> void:
	if Engine.is_editor_hint():
		shape_changed = true


func update_size() -> void:
	size = Vector3(edge_chunks, 1, edge_chunks) * chunk_size
	shape_changed = true


func heightmap(x: float, z: float) -> float:
	var noise_a = height_noise_a.get_noise_2d(x * density_a, z * density_a) * height_a
	var noise_b = height_noise_b.get_noise_2d(x * density_b, z * density_b) * height_b
	var noise_c = height_noise_c.get_noise_2d(x * density_c, z * density_c) * height_c
	var noise = noise_a + noise_b + noise_c
	if not use_texture_a:
		return noise


	#print("called this function")
	var scaled_x = (x+size.x/2) / size.x * image_a_width
	var scaled_y = (z+size.z/2) / size.z * image_a_height
	scaled_x = clamp(scaled_x, 0, image_a_width - 1)
	scaled_y = clamp(scaled_y, 0, image_a_height- 1)
	
	var pixel_color = image_a.get_pixel(scaled_x, scaled_y)
	var curve_point = color_curve.sample(pixel_color.r)
	
	#return curve_point * (noise * tanh(noise * 1.1) + 1)
	var new_height = curve_point * height_a  + noise_c
	if new_height > 4:
		new_height += noise_b * smoothstep(4, 10, new_height)
	
	return new_height


func pos_from_map(x: float, z:float) -> Vector3:
	return Vector3(x, heightmap(x, z), z)


func coord_from_idx(idx: int) -> Vector2:
	if idx == 0:
		return Vector2(0,0)
	
	var cycle = int(ceil(floor(sqrt(idx)) / 2.0))
	var idx_into_cycle = int(idx - (4.0 * cycle * (cycle - 1.0) + 1.0))
	var turn = int(floor(float(idx_into_cycle) / (2.0 * cycle)))
	const corners = [Vector2(-1, 1), Vector2(1, 1), Vector2(1, -1), Vector2(-1, -1)]
	const steps = [Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0), Vector2(0, 1)]
	
	return cycle * corners[turn] + (1 + idx_into_cycle % (2 * cycle)) * steps[turn]


func get_x_dist(idx: int) -> float:
	return idx - float(edge_chunks - 1) / 2


func get_z_dist(idx: int) -> float:
	return idx - float(edge_chunks - 1) / 2


func get_subdivisions(x_idx: int, z_idx: int) -> int:
	match detail_mode:
		DetailMode.DISTANCE:
			var dist = max(abs(get_x_dist(x_idx)), abs(get_x_dist(z_idx)))
			
			if dist >= 3.5:
				return subdivisions - 2
			if dist >= 1.5:
				return subdivisions - 1
		DetailMode.LOW:
			return subdivisions - 2
		DetailMode.MEDIUM:
			return subdivisions - 1
	
	return subdivisions


func update_material() -> void:
	for patch_row in patches:
		for patch: TerrainPatch in patch_row:
			patch.update_material(material)


func randomize_seed() -> void:
	shape_changed = true
	seed = randi()


func generate_mesh() -> void:
	print("Started generating terrain...\n")
	var start_time := Time.get_unix_time_from_system()
	
	var children = get_children()
	for child in children:
		child.queue_free()
	
	var initial_position = Vector3(chunk_size.x, 0, chunk_size.z) * (edge_chunks - 1) * -0.5
	if use_texture_a:
		#image_a = texture_a.get_image()
		image_a = Image.load_from_file("res://dungeon crawler/src/cave/new map/map v5.png")
		image_a_width = image_a.get_width()
		image_a_height = image_a.get_height()
	
	patches = []
	for z in edge_chunks:
		patches.append([])
		for x in edge_chunks:
			patches[z].append(null)
	
	for i in edge_chunks ** 2:
		var coord = coord_from_idx(i) + Vector2((edge_chunks - 1) / 2, (edge_chunks - 1) / 2)
		var x = coord.x
		var z = coord.y
		
		var chunk_subdivisions = get_subdivisions(x, z)
		
		var x_dist = get_x_dist(x)
		var z_dist = get_z_dist(z)
		var north_south = abs(x_dist) < abs(z_dist)
		
		var transition := TerrainPatch.Transition.NONE
		if abs(x_dist) == abs(z_dist):
			pass
		elif north_south:
			if z_dist < 0 && get_subdivisions(x, z + 1) != chunk_subdivisions:
				transition = TerrainPatch.Transition.SOUTH
			if z_dist > 0 && get_subdivisions(x, z - 1) != chunk_subdivisions:
				transition = TerrainPatch.Transition.NORTH
		else:
			if x_dist < 0 && get_subdivisions(x + 1, z) != chunk_subdivisions:
				transition = TerrainPatch.Transition.EAST
			if x_dist > 0 && get_subdivisions(x - 1, z) != chunk_subdivisions:
				transition = TerrainPatch.Transition.WEST
		
		var patch = PATCH.instantiate()
		patches[z].set(x, patch)
		patch.initialize(self, x, z, chunk_subdivisions, chunk_size,
		diagonal_type, material, transition)
		
		add_child(patch)
		patch.position = initial_position + chunk_size * Vector3(x, 0, z)
		if Engine.is_editor_hint() && is_inside_tree():
			patch.set_owner(get_tree().get_edited_scene_root())
		
		patch.generate_mesh()
	
	# update foliage spread area and water size if shape is new
	if shape_changed:
		shape_changed = false
		var foliage : FoliageGenerator = get_parent().find_child("*FoliageGenerator*")
		if foliage:
			foliage.init_foliage()
			
		var water = get_parent().find_child("*WaterPlane*")
		if water:
			water.mesh.size = edge_chunks * Vector2(chunk_size.x, chunk_size.z)
			var normal_A = water.mesh.material.get_shader_parameter("normal_map_a") 
			normal_A.width = edge_chunks * 200
			normal_A.height = edge_chunks * 200
			water.mesh.material.set_shader_parameter("normal_map_a", normal_A)
			
			var normal_B = water.mesh.material.get_shader_parameter("normal_map_b") 
			normal_B.width = edge_chunks * 200
			normal_B.height = edge_chunks * 200
			water.mesh.material.set_shader_parameter("normal_map_b", normal_B)
	
	var duration := Time.get_unix_time_from_system() - start_time;
	print("Completed terrain generation in ", "%0.3f" % duration, " seconds.\n\n")
