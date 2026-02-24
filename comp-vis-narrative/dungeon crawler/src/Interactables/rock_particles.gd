extends GPUParticles3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
	# play the particle
	emitting = true
	one_shot = true
	await get_tree().create_timer(1 + 0.5).timeout
	
	# kill yourself
	queue_free()
