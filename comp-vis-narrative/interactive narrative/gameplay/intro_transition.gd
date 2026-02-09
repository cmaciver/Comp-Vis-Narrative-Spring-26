extends Node
class_name IntroTransitionManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func intro_step(step: int):
	var tween = get_tree().create_tween()
	
	# shoot out a few particles
	if step == 1:
		tween.tween_property($particles, "amount_ratio", 0.01, 2.0)
	
	# shoot more particles and small ripple
	if step == 2:
		tween.tween_property($particles, "amount_ratio", 0.3, 3.0)
		
		tween.tween_method(
			func(value): 
				$Ripple/ColorRect.material.set_shader_parameter("max_radius", value),
				0, 0.3, 3.0,
		);
		$Ripple/ColorRect.material.set_shader_parameter("displacement_amount", 0.01)

	
	# player decision happens after this
	if step == 3:
		tween.tween_property($particles, "amount_ratio", 1.0, 3.0)
		
		tween.tween_method(
			func(value): 
				$Ripple/ColorRect.material.set_shader_parameter("max_radius", value), 
				0, 0.5, 3.0,
		);
		tween.tween_method(
			func(value): 
				$Ripple/ColorRect.material.set_shader_parameter("brightness_diff", value),
				1.0, 1.1, 3.0,
		);
		$Ripple/ColorRect.material.set_shader_parameter("displacement_amount", 0.1)
	
	# begin to ease up AND FADE IN THE NEXT SCENE
	if step == 4:
		tween.tween_property($particles, "amount_ratio", 0.0, 5.0)
		
		tween.tween_method(
			func(value): 
				$Ripple/ColorRect.material.set_shader_parameter("max_radius", value), 
				0, 0.5, 3.0,
		);
		tween.tween_method(
			func(value): 
				$Ripple/ColorRect.material.set_shader_parameter("brightness_diff", value),
				1.0, 1.1, 3.0,
		);
		$Ripple/ColorRect.material.set_shader_parameter("displacement_amount", 0.1)
		
	if step == 5:
		pass
	
