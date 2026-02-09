extends Node2D

var current_scene
var current_vignette : Vignette
@onready var audio_manager: AudioManager = $AudioManager

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
		"start"
		#"ending_3" # change back to "start" later
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func change_scene(path, timing_overide=1.5):
	
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


## AUDIO
## See audio_manager.gd for details
func switch_background_music(key: String, fade_time: float = 8.0) -> void:
	audio_manager.switch_background_music(key, fade_time)

func play_sound_effect(key: String) -> void:
	audio_manager.play_sound_effect(key)


## ADDING AND REMOVING CHARACTERS

# Add character will add the given character to the scene if it doesn't exist, 
# and if it does exist, it will move the pre-existing character to the given position. 
# This assumes that we only ever want one instance of each character on the screen at a time.
func add_character(path, pos=Vector2(960, 540)):
	var new_scene_resource = load(path) # maybe find a less laggy way to do this?
	var new_scene_instance = new_scene_resource.instantiate()
	var character_id = new_scene_instance.name
	new_scene_instance.set_meta("character_id", character_id)
	var existing_character = find_character_by_id(character_id)

	# If the character already exists, just move it to the new position and return
	if existing_character:
		existing_character.position = pos
		return
	$Characters.add_child(new_scene_instance)
	
	new_scene_instance.position = pos

# Given a character ID, finds the character node in the characters node with that ID and returns it. 
# If no such character exists, returns null.
func find_character_by_id(character_id: String) -> Character:
	for child in $Characters.get_children():
		if child is Character and child.get_meta("character_id", "") == character_id:
			return child
	return null

# Given a character ID, finds the character with that ID and calls its fade_out function, 
# which will fade it out and then remove it from the scene. Or does nothing if no such character exists I guess...
func remove_character(c_name: String):
	var child = find_character_by_id(c_name)
	if child:
		child.fade_out()

# This function shall fade all characters in the characters node out,
# except for any characters whose IDs are in the keep_ids array.
func remove_all_characters(keep_ids: Array = []):
	for child in $Characters.get_children():
		if child is Character:
			var character_id = child.get_meta("character_id", "")
			if keep_ids.has(character_id):
				continue
			child.fade_out()

# Shorthand for calling remove_all_characters
# with a keep_ids array that keeps the character of the current POV alive.
func remove_all_characters_keep_pov():
	var keep_prefix = "Tri" if Globals.POV == "Triceratops" else "Tyran"
	var keep_ids: Array = []
	for child in $Characters.get_children():
		if child is Character:
			var character_id = str(child.get_meta("character_id", ""))
			if character_id.begins_with(keep_prefix):
				keep_ids.append(character_id)
	remove_all_characters(keep_ids)


# MANAGING THE RIPPLE
func set_ripple_size(size: int):
	$Ripple.set_ripple_size(size)


## TIME OF DAY STUFF
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

#
#func render_prey():
	#if (Globals.prey == "alligator"):
		#pass
		## TODO
	#
	#if (Globals.time == "turtle"):
		#pass
		## TODO
