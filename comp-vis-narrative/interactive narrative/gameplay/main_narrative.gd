extends Node2D

var current_scene
var current_vignette : Vignette

var vignette = preload("res://interactive narrative/shaders/Vignette.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.time = "morning" # having default values for these is probably only a good thing
	Globals.prey = "turtle"
	Globals.POV = "NanoTyrannus"
	Globals.nano_hurt_head = false
	
	DialogueManager.show_dialogue_balloon_scene(
		load("res://interactive narrative/gameplay/balloon.tscn"), 
		load("res://interactive narrative/gameplay/main.dialogue"),
		"environment"
		#"ending_3" # change back to "start" later
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func add_scene(path, timing_overide=1.5):
	
	if current_scene:
		current_vignette.tween_opacity(1.0, 0.0, timing_overide)
		await get_tree().create_timer(timing_overide).timeout
	
	# make new scene
	var new_scene_resource = load(path) # maybe find a less laggy way to do this?
	var new_scene_instance = new_scene_resource.instantiate()
	add_child(new_scene_instance)
	current_scene = new_scene_instance
	
	# add a vignette
	var new_vignette : Vignette = vignette.instantiate()
	current_scene.add_child(new_vignette)
	current_vignette = new_vignette
	
	if timing_overide != 1.5: # maybe refactor this out of here, and just always call this
		current_vignette.autoplay = false
		current_vignette.tween_opacity(0.0, 1.0, timing_overide)

func set_ripple_size(size: int):
	$Ripple.set_ripple_size(size)


func update_game_time():
	print("this works, you can just name any function in this script and it just does it")
	if (Globals.time == "morning"):
		pass
		# TODO
	
	if (Globals.time == "noon"):
		pass
		# TODO
	
	if (Globals.time == "night"):
		pass
		# TODO


func render_prey():
	if (Globals.prey == "alligator"):
		pass
		# TODO
	
	if (Globals.time == "turtle"):
		pass
		# TODO
