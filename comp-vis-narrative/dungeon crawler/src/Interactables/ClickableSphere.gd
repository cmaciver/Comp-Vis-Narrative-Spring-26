extends Area3D

signal dot_clicked

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.input_event.connect(_on_input_event)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#func _on_input_event(camera, event, position, normal, shape_idx):
	#print("Input event detected: ", event)
	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#print("Click detected!")
		#emit_signal("dot_clicked")
		#queue_free()


func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	#print("HREHREHRHER")
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true:
			print("clicked the point")
			emit_signal("dot_clicked")
			queue_free()
