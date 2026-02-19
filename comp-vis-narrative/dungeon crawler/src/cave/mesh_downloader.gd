extends Node3D

func _ready() -> void:
	save_all_meshes()
	OBJExporter.export_started.connect(_on_export_started)
	OBJExporter.export_completed.connect(_on_export_completed)
	OBJExporter.export_progress_updated.connect(_on_export_progress)

func save_all_meshes():
	var chunks = $TerrainGenerator.get_children()
	var chunkNum = 0
	for chunk in chunks:
		var mesh = chunk.get_child(0)
		if mesh is not MeshInstance3D:
			continue
		else:
			chunkNum += 1
			OBJExporter.save_mesh_to_files(mesh.mesh, "C:\\Users\\aguia\\Documents", "chunk_" + str(chunkNum))
		
func _on_export_started():
	print("export started")
	
func _on_export_completed(obj, mtl):
	print("export completed! " + str(obj))
	
func _on_export_progress(idx, progress):
	print("export progress: " + str(progress))
