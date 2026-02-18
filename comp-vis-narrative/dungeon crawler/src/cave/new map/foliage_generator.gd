@tool
extends Node3D
class_name FoliageGenerator

@export var foliage_subdivisions := 6

@export_tool_button("Generate Foliage") var generate_button = scatter_foliage

var terrain : TerrainGenerator
var water_level := -99999.9
var rng = RandomNumberGenerator.new()

@onready var trees : Array[PackedScene] = [
	#preload("res://Testing Assets/Trees/tree_1.tscn"),
	#preload("res://Testing Assets/Trees/tree_2.tscn"),
	#preload("res://Testing Assets/Trees/tree_3.tscn"),
	#preload("res://Testing Assets/Trees/tree_4.tscn"),
	#preload("res://Testing Assets/Trees/tree_5.tscn"),
]

@onready var bushes : Array[PackedScene] = [
	#preload("res://Testing Assets/Bushes/bush_1.tscn"),
	#preload("res://Testing Assets/Bushes/bush_2.tscn"),
	#preload("res://Testing Assets/Bushes/bush_3.tscn"),
	#preload("res://Testing Assets/Bushes/bush_4.tscn"),
	#preload("res://Testing Assets/Bushes/bush_5.tscn"),
	#preload("res://Testing Assets/Bushes/bush_6.tscn"),
]

@onready var rocks : Array[PackedScene] = [
	#preload("res://Testing Assets/Rocks/rock_1.tscn"),
	#preload("res://Testing Assets/Rocks/rock_2.tscn"),
	#preload("res://Testing Assets/Rocks/rock_3.tscn"),
	#preload("res://Testing Assets/Rocks/rock_4.tscn"),
	#preload("res://Testing Assets/Rocks/rock_5.tscn"),
	#preload("res://Testing Assets/Rocks/rock_6.tscn"),
]


var initialized = false


func init_foliage():
	rng.seed = Time.get_ticks_usec()
	terrain = get_parent().find_child("*TerrainGenerator*")
	var water = get_parent().find_child("*WaterPlane*")
	if water:
		print("inited")
		water_level = water.position.y
	
	if not terrain:
		print("uhoh, no terrain")
		return
	
	initialized = true
	scatter_foliage()


func scatter_foliage():
	if !initialized:
		init_foliage()
		return
	
	
	for child in get_children():
		child.queue_free()
	
	
	for i in range(foliage_subdivisions * terrain.edge_chunks):
		for j in range(foliage_subdivisions * terrain.edge_chunks):
			var rand = rng.randf()
			var pos = select_random_point(i, j)
			
			
			if pos.y < water_level: #rock only
				var new_foliage = create_object(rocks)
				new_foliage.position = pos + rng.randf_range(0, 1) * Vector3.DOWN
				new_foliage.rotation.y = rng.randf_range(0, 2 * PI)
				new_foliage.rotation.x = rng.randf_range(0, PI / 12) # 1/24 of a circle
				new_foliage.rotation.z = rng.randf_range(0, PI / 12)
				continue
			
			# chance to skip entirely
			if rand < 0.6:
				continue
			
			elif rand < 0.7: # tree
				var new_foliage = create_object(trees)
				new_foliage.position = pos
			
				new_foliage.rotation.y = rng.randf_range(0, 2 * PI)
				new_foliage.rotation.x = rng.randf_range(0, PI / 12) # 1/24 of a circle
				new_foliage.rotation.z = rng.randf_range(0, PI / 12)

				
			elif rand < 1.0: # bush
				var new_foliage = create_object(bushes)
				new_foliage.position = pos
			
				new_foliage.rotation.y = rng.randf_range(0, 2 * PI)
				new_foliage.rotation.x = rng.randf_range(0, PI / 12) # 1/24 of a circle
				new_foliage.rotation.z = rng.randf_range(0, PI / 12)

			
			
			


## select the foliage type and place it in the world
func create_object(scene_array: Array[PackedScene]):
	var type = scene_array.pick_random()
	var new_foliage = type.instantiate()
	
	add_child(new_foliage)
	if Engine.is_editor_hint():
		new_foliage.set_owner(get_tree().get_edited_scene_root())
	
	return new_foliage


func select_random_point(cell_x, cell_z):
	var width = terrain.size.x / foliage_subdivisions / terrain.edge_chunks
	var length = terrain.size.z / foliage_subdivisions / terrain.edge_chunks 
	
	var x = cell_x * width + rng.randf_range(0, width) - terrain.size.x / 2
	var z = cell_z * length + rng.randf_range(0, length) - terrain.size.z / 2
	var y = terrain.heightmap(x, z)
	
	return Vector3(x, y, z)
