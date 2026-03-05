extends Control

var displayedFossil

func load_entry(entry: Dictionary, index: int):
	$FossilNumberLabel.text = "Fossil #%d/%d" % [index + 1, DungeonCrawlerData.collectedLogs.size()]
	$FossilTimeFoundLabel.text = "Time Found: " + entry["time"]
	%FieldLog.updateWithFossilInfo(entry.initials, entry.description)
	load_fossil(entry["fossil_path"])

#load in the fossil into the subviewport and then rotate it
func load_fossil(path: String):
	var viewport = $SubViewportContainer/SubViewport

 	# Remove any existing fossil
	for child in viewport.get_children():
		if child is Node3D and child.name != "Camera3D" and child.name != "DirectionalLight3D" and child.name != "BackgroundMesh":
			child.queue_free()

	# Load and add the new one
	var fossil_scene = load(path)
	var fossil = fossil_scene.instantiate()
	viewport.add_child(fossil)
	
	fossil.gravity_scale = 0
	fossil.freeze = true
	displayedFossil = fossil


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if displayedFossil:
		displayedFossil.rotate_y(delta * 0.5)
