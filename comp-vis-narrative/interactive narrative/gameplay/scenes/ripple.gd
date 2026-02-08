extends CanvasLayer

var old_max_radius = 0.0
var old_displacement_amount = 0.0
var old_brightness_diff = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func set_ripple_size(size: int):
	var max_radius
	var displacement_amount
	var brightness_diff

	if size == 0:
		#max_radius = 0.0
		displacement_amount = 0.00
		brightness_diff = 1.00
	
	if size == 1:
		max_radius = 0.5
		displacement_amount = 0.05
		brightness_diff = 1.05
		
	if size == 2:
		max_radius = 0.75
		displacement_amount = 0.1
		brightness_diff = 1.1

	var tween = get_tree().create_tween()
		
	var duration = 10.0
	tween.tween_method(
	func(value): $ColorRect.material.set_shader_parameter("max_radius", value),  
		old_max_radius,  # Start value
		max_radius,  # End value
		duration # Duration
	);
	
	tween.tween_method(
	func(value): $ColorRect.material.set_shader_parameter("displacement_amount", value),  
		old_displacement_amount,  # Start value
		displacement_amount,  # End value
		1.0 # Duration
	);
	
	tween.tween_method(
	func(value): $ColorRect.material.set_shader_parameter("brightness_diff", value),  
		old_brightness_diff,  # Start value
		brightness_diff,  # End value
		duration # Duration
	);
	
	old_max_radius = max_radius
	old_displacement_amount = displacement_amount
	old_brightness_diff = brightness_diff
