extends MeshInstance3D

var time = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta
	
	var scale = 1 + 0.3 * sin(time * 5)
	
	mesh.size.x = 0.1 * scale
	mesh.size.y = 0.1 * scale
