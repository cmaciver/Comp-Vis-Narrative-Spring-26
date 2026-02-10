extends Node
class_name IntroTransitionManager

var landscape = preload("res://interactive narrative/gameplay/scenes/landscape.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func intro_step(step: int):
	print("running intro transition: ", step)
	var trans_time = 5.0
	
	$AnimationPlayer.play_section("new_animation", step-1, step, -1, 1 / trans_time)
	
	# load the landscape BASED ON THE TIME OF DAY
	if step == 4:
		var land = landscape.instantiate()
		add_sibling(land)
		
		
		var image = land.get_node("image")
		image.modulate = Color.TRANSPARENT
		var tween = get_tree().create_tween()
		tween.tween_property(image, "modulate", Color.WHITE, trans_time)
		
		
		# set the TIME
		if (Globals.time == "morning"):
			land.get_node("EVENING").visible = true
			var tween2 = get_tree().create_tween()
			tween2.tween_method(
			func(value): land.get_node("EVENING/ColorRect").material.set_shader_parameter("mix_amount", value),  
				0.0,  # Start value
				1.0,  # End value
				trans_time # Duration
			);
			
	
		if (Globals.time == "noon"):
			pass
		
		if (Globals.time == "night"):
			land.get_node("NIGHT").visible = true
		
			var tween2 = get_tree().create_tween()
			tween2.tween_method(
			func(value): land.get_node("NIGHT/ColorRect").material.set_shader_parameter("mix_amount", value),  
				0.0,  # Start value
				1.0,  # End value
				trans_time # Duration
			);
		
		
		
	if step == 5:
		queue_free()
	
