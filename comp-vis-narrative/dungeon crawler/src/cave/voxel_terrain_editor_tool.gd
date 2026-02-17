@tool
extends Node3D

@onready var voxel_terrain : VoxelTerrain = $"../VoxelTerrain"
@onready var cursor_sphere := $"../CursorSphere"
@onready var cursor_cube := $"../CursorCube"

@onready var voxel_tool : VoxelTool = voxel_terrain.get_voxel_tool()

## Editor tool properties
@export var tool_is_active : bool = false

enum ToolType {
	Add,
	Remove,
	Height,
	Smooth
}
@export var tool_mode : ToolType = ToolType.Remove


@export_range(0.5, 10, 0.1) var tool_size : float = 2.0
@export_range(0, 20, 0.1) var tool_distance : float = 6.0

@export_range(0, 20, 1) var desired_height : float = 0.0

## save button
@export_tool_button("Save Terrain")
var save_action = save_terrain


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tool_is_active = false
	
	if Engine.is_editor_hint():
		voxel_terrain.stream = VoxelStreamRegionFiles.new()
		voxel_terrain.stream.directory = "res://dungeon crawler/src/cave/data/"
	
	if not Engine.is_editor_hint():
		voxel_terrain.stream = VoxelStreamRegionFiles.new()
		voxel_terrain.stream.directory = "res://dungeon crawler/src/cave/data_runtime/"
		
		# we completely should not even have this script running during gameplay
		cursor_sphere.queue_free()
		cursor_cube.queue_free()
		queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta: float) -> void:
	#var camera = EditorInterface.get_editor_viewport_3d().get_camera_3d()
	#var camera_forward_vector: Vector3 = -camera.global_transform.basis.z
	#
	#var material = cursor_sphere.mesh.material
	#material.albedo_color = Color("ffffff80")
	#if tool_is_active:
		#material.albedo_color = Color("ff004080")
	#
	## TODO also add option to raycast and just increase decrease height
	## height tool
	#if tool_mode == ToolType.Height:
		#cursor_sphere.visible = false
		#cursor_cube.visible = true
		#var result = voxel_tool.raycast(camera.position, camera_forward_vector, 1000)
		#if result:
			#var marker_pos = result.position
			#
			#cursor_cube.scale = Vector3.ONE * tool_size * 2
			#cursor_cube.position = marker_pos
			#var current_height = marker_pos.y
			#marker_pos.y = 0
			#cursor_cube.position.y = desired_height - tool_size + 0.1 # maybe this should be in both?
			#
			#if tool_is_active:
				#if current_height < desired_height:
					## need to raise
					#voxel_tool.mode = VoxelTool.MODE_ADD
					#
					## TODO
					#var width = int(tool_size)
					#var top_corner = Vector3i(width, int(desired_height), width)
					#var bottom_corner = Vector3i(-width, -100, -width)
					#voxel_tool.do_box(marker_pos + bottom_corner, marker_pos + top_corner)
					##print("yeah")
					#
					##voxel_tool.do_sphere(marker_pos, tool_size)
					#
				#else:
					### need to raise
					#voxel_tool.mode = VoxelTool.MODE_REMOVE
					#
					#var width = int(tool_size)
					#var top_corner = Vector3i(width, 100, width)
					#var bottom_corner = Vector3i(-width, int(desired_height), -width)
					#voxel_tool.do_box(marker_pos + bottom_corner, marker_pos + top_corner)
	#
	#elif tool_mode == ToolType.Smooth:
		#cursor_sphere.visible = true
		#cursor_cube.visible = false
		#var result = voxel_tool.raycast(camera.position, camera_forward_vector, 100)
		#if result:
			#var marker_pos = result.position
			#
			#cursor_sphere.scale = Vector3.ONE * tool_size * 2
			#cursor_sphere.position = marker_pos
			#cursor_sphere.position.y = desired_height
			#
			#if tool_is_active:
				#
				#voxel_tool.smooth_sphere(marker_pos, tool_size, 2)
		#
	#
	### sculpt tool
	#else:
		#cursor_sphere.visible = true
		#cursor_cube.visible = false
		#var marker_pos = camera.global_position + camera_forward_vector * tool_distance
#
		#cursor_sphere.scale = Vector3.ONE * tool_size * 2
		#cursor_sphere.position = marker_pos
		#
		##var material = cursor_sphere.mesh.material
		##material.albedo_color = Color("ffffff80")
		#
		#if tool_is_active:
			#if tool_mode == ToolType.Add: voxel_tool.mode = VoxelTool.MODE_ADD
			#if tool_mode == ToolType.Remove: voxel_tool.mode = VoxelTool.MODE_REMOVE
			#
			#voxel_tool.do_sphere(marker_pos, tool_size)
			## TODO also add ability to box
			#
			#cursor_sphere.visible = true
			##material.albedo_color = Color("ff004080")
		#
	#
#
#
### auto writes the data version on scene save
##func _notification(notif):
	##if notif == NOTIFICATION_EDITOR_POST_SAVE:
		##save_terrain()


func save_terrain():
	var save_tracker = voxel_terrain.save_modified_blocks()
	
	while true:
		await get_tree().create_timer(0.5).timeout
		if save_tracker.is_complete(): break
		if save_tracker.is_aborted():  return
	
	# remove the runtime directory
	var err
	err = remove_directory_recursive("res://dungeon crawler/src/cave/data_runtime/")
	voxel_terrain.stream = null
	
	# replace the runtime directory
	err = copy_directory_recursive("res://dungeon crawler/src/cave/data/", "res://dungeon crawler/src/cave/data_runtime/")
	voxel_terrain.stream = VoxelStreamRegionFiles.new()
	voxel_terrain.stream.directory = "res://dungeon crawler/src/cave/data/"

	if err == OK:
		print("Saved Mesh Successfully")
		cursor_sphere.visible = false # just a nice to have i guess
		cursor_cube.visible = false


## adapted from stackoverflow post for godot 4.5
func remove_directory_recursive(directory_path: String) -> Error:
	# check if it exists
	var directory := DirAccess.open(directory_path)
	if not directory:
		return ERR_FILE_NOT_FOUND # source doesnt exist
	
	# call recursive all directories
	for dir_name in DirAccess.get_directories_at(directory_path):
		remove_directory_recursive(directory_path.path_join(dir_name))
	
	# delete all files
	for file_name in DirAccess.get_files_at(directory_path):
		DirAccess.remove_absolute(directory_path.path_join(file_name))

	# then, remove this one
	DirAccess.remove_absolute(directory_path)
	return OK


## adapted from stackoverflow post for godot 4.5
func copy_directory_recursive(source_dir_path: String, dest_dir_path: String) -> Error:
	# open the old directory
	var source_dir_access := DirAccess.open(source_dir_path)
	if not source_dir_access:
		return ERR_FILE_NOT_FOUND # source doesnt exist
	
	# make the new directory
	var error := DirAccess.make_dir_recursive_absolute(dest_dir_path)
	if error != OK:
		return error # destination can't be created

	# iterate through all in this file/directory
	source_dir_access.list_dir_begin()
	var current_filename := source_dir_access.get_next()
	while current_filename != "":
		# make the full paths for source and destination
		var from_path := source_dir_path.path_join(current_filename)
		var to_path := dest_dir_path.path_join(current_filename)

		if source_dir_access.current_is_dir():
			# call recursive for directories
			error = copy_directory_recursive(from_path, to_path)
			if error != OK:
				source_dir_access.list_dir_end()
				return error

		else:
			# just copy the file
			error = source_dir_access.copy(from_path, to_path)
			if error != OK:
				source_dir_access.list_dir_end()
				return error

		current_filename = source_dir_access.get_next()

	source_dir_access.list_dir_end()
	return OK
