extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.time = "morning" # having default values for these is probably only a good thing
	Globals.prey = "turtle"
	Globals.POV = "NanoTyrannus"
	Globals.nano_hurt_head = false
	
	DialogueManager.show_dialogue_balloon_scene(
		load("res://interactive narrative/gameplay/balloon.tscn"), 
		load("res://interactive narrative/gameplay/test_dialogue.dialogue"),
		"start"
		#"ending_3" # change back to "start" later
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

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
