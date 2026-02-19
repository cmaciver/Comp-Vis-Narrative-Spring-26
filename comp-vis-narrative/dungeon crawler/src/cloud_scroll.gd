extends WorldEnvironment

var cloud_noise

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cloud_noise = environment.sky.sky_material.get("shader_parameter/cloud_shape_sampler")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	await get_tree().create_timer(0.01).timeout
	cloud_noise.noise.offset.x += 0.001
