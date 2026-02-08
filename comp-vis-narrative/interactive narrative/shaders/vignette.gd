extends CanvasLayer
class_name Vignette

@export var autoplay : bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if autoplay:
		tween_opacity()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func tween_opacity(start_val=0.0, end_val=1.0, duration=3.0):
	var tween = get_tree().create_tween()	
	# args are: (method to call / start value / end value / duration of animation)
	tween.tween_method(set_shader_value, start_val, end_val, duration); 


func set_shader_value(value: float):
	# in my case i'm tweening a shader on a texture rect, but you can use anything with a material on it
	$ColorRect.material.set_shader_parameter("trans_timer", value);
