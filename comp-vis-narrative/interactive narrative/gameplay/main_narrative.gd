extends Node2D

var current_scene
var current_scene_path: String = ""
var current_vignette : Vignette
@onready var audio_manager: AudioManager = $AudioManager

var vignette = preload("res://interactive narrative/shaders/Vignette.tscn")

# Time-of-day shader resources used to tint certain scenes.
var evening_shader: Shader = preload("res://interactive narrative/shaders/src/evening.gdshader")
var night_shader: Shader = preload("res://interactive narrative/shaders/src/nighttime.gdshader")

# Scenes that should always respect the time-of-day shader.
# Scenes outside of this list will not have the time-of-day shader applied, 
# even if they are still changed to become the current scene/are the current scene.
const TIME_TINTED_SCENES := {
	"res://interactive narrative/gameplay/scenes/landscape.tscn": true,
	"res://interactive narrative/gameplay/scenes/cave.tscn": true,
	"res://interactive narrative/gameplay/scenes/flood.tscn": true,
}

var rain = preload("res://interactive narrative/gameplay/scenes/rain.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.time = "morning" # having default values for these is probably only a good thing
	Globals.prey = "turtle"
	Globals.POV = "NanoTyrannus"
	Globals.nano_hurt_head = false
	Globals.in_cave = false
	
	DialogueManager.show_dialogue_balloon_scene(
		load("res://interactive narrative/gameplay/balloon.tscn"), 
		load("res://interactive narrative/gameplay/main.dialogue"),
		"start"
		#"environment"
		#"ending_2"
		#"ending_3" # change back to "start" later
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# Ensures scenes tagged in TIME_TINTED_SCENES render with the correct time-of-day shader overlays.
func apply_time_of_day_to_scene(scene: Node, path: String) -> void:
	# No scene, no shader application to do.
	if not scene:
		return

	# Ensures that scenes like the fossil background and earf 
	# which shouldn't be tinted with the shader
	# do not get tinted with the time of day shader.
	if not TIME_TINTED_SCENES.has(path):
		return

	# Inside of the landscape scene, it seems that the way the shaders are set up
	# is that there are two separate CanvasLayers, one for the evening shader and one for the night shader, 
	# that are toggled on and off depending on the time of day. 
	# So here, in order to apply the time of day shaders to the scene, we first check if those CanvasLayers already exist
	# (so that we don't end up stacking multiple layers on top of each other if we change scenes multiple times),
	# and if they don't, we create them and add them to the scene. Then we toggle their visibility based on the current time of day.

	# [node name="EVENING" type="CanvasLayer" parent="."]
	# visible = false

	# [node name="NIGHT" type="CanvasLayer" parent="."]
	# visible = false

	# We first check for the existence of the layers by name
	var evening_layer: CanvasLayer = scene.get_node_or_null("EVENING")
	var night_layer: CanvasLayer = scene.get_node_or_null("NIGHT")

	# If we're in the cave, we should apply a less intense shader effect, 
	# since 1.0 makes it really dark with both the evening/morning and night shaders.
	var is_cave := path == "res://interactive narrative/gameplay/scenes/cave.tscn"

	# It also looks a bit weird in the flood scene.
	var is_flood := path == "res://interactive narrative/gameplay/scenes/flood.tscn"

	var evening_mix := 1.0
	var night_mix := 1.0

	if is_cave:
		evening_mix = 0.55
		night_mix = 0.7
	elif is_flood:
		evening_mix = 0.85
		night_mix = 0.7 

	# If the evening layer doesn't exist, we create it.
	# To figure out what must go into this evening layer, 
	# I read through the landscape scene and found the existing
	# evening layer and examined its properties and children, and replicated those here in code.
	if not evening_layer:
		evening_layer = CanvasLayer.new()
		evening_layer.name = "EVENING"
		# [node name="ColorRect" type="ColorRect" parent="EVENING"]
		# material = SubResource("ShaderMaterial_kl005")  # ShaderMaterial_kl005 comes from shader = ExtResource("4_fcwcu"), where ExtResource("4_fcwcu") is the evening shader resource. 
		# anchors_preset = 15
		# anchor_right = 1.0
		# anchor_bottom = 1.0
		# grow_horizontal = 2
		# grow_vertical = 2
		var evening_rect := ColorRect.new()
		evening_rect.name = "ColorRect"
		evening_rect.anchor_right = 1.0
		evening_rect.anchor_bottom = 1.0
		# https://docs.godotengine.org/en/stable/classes/class_control.html#enum-control-growdirection
		# 2 corresponds to GrowDirection GROW_BOTH
		evening_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH 
		evening_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
		# https://docs.godotengine.org/en/stable/classes/class_control.html#class-control-method-set-anchors-preset
		# https://docs.godotengine.org/en/stable/classes/class_control.html#enum-control-layoutpreset
		# 15 corresponds to LayoutPreset PRESET_FULL_RECT
		evening_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		var evening_material := ShaderMaterial.new()
		evening_material.shader = evening_shader
		# https://docs.godotengine.org/en/stable/classes/class_shadermaterial.html#class-shadermaterial-method-set-shader-parameter
		# [sub_resource type="ShaderMaterial" id="ShaderMaterial_kl005"]
		# shader = ExtResource("4_fcwcu")
		# shader_parameter/mix_amount = 1.0
		# shader_parameter/red_shift = 0.03999999910592
		# shader_parameter/yellow_shift = 0.01999999955296
		# shader_parameter/gamma_adjust = 2.00999997742448
		evening_material.set_shader_parameter("mix_amount", evening_mix)
		evening_material.set_shader_parameter("red_shift", 0.04)
		evening_material.set_shader_parameter("yellow_shift", 0.02)
		evening_material.set_shader_parameter("gamma_adjust", 2.01)
		evening_rect.material = evening_material
		evening_layer.add_child(evening_rect)
		scene.add_child(evening_layer)

	if not night_layer:
		night_layer = CanvasLayer.new()
		night_layer.name = "NIGHT"
		# [node name="ColorRect" type="ColorRect" parent="NIGHT"]
		# material = SubResource("ShaderMaterial_bv3t5") # Like the evening shader, ShaderMaterial_bv3t5 corresponds to ExtResource("1_gtdpo"), which is the night shader resource.
		# anchors_preset = 15
		# anchor_right = 1.0
		# anchor_bottom = 1.0
		# grow_horizontal = 2
		# grow_vertical = 2
		var night_rect := ColorRect.new()
		night_rect.name = "ColorRect"
		night_rect.anchor_right = 1.0
		night_rect.anchor_bottom = 1.0
		night_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH 
		night_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
		night_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		var night_material := ShaderMaterial.new()
		night_material.shader = night_shader
		# [sub_resource type="ShaderMaterial" id="ShaderMaterial_bv3t5"]
		# shader = ExtResource("1_gtdpo")
		# shader_parameter/mix_amount = 1.0
		# shader_parameter/switch_point = 0.5
		# shader_parameter/spec_pow = 7.4
		# shader_parameter/gamma_adjust = 2.4
		# shader_parameter/color = Vector3(0, 0, 0.01)
		night_material.set_shader_parameter("mix_amount", night_mix)
		night_material.set_shader_parameter("switch_point", 0.5)
		night_material.set_shader_parameter("spec_pow", 7.4)
		night_material.set_shader_parameter("gamma_adjust", 2.4)
		night_material.set_shader_parameter("color", Vector3(0, 0, 0.01))
		night_rect.material = night_material
		night_layer.add_child(night_rect)
		scene.add_child(night_layer)

	# Toggle overlays based on Globals.time
	if evening_layer:
		evening_layer.visible = Globals.time == "morning"
	if night_layer:
		night_layer.visible = Globals.time == "night"

	# Ensure any existing characters pick up the current time-of-day tint immediately.
	retint_all_characters()


# Applies the same time-of-day tint logic used by Character._ready() to all current characters.
# Used when applying the time-of-day shader overlays to a scene to ensure that any characters 
# that are already present in the scene get to be appropriately tinted immediately, 
# as the _ready function's tinting only applies when the node enters the scene tree for the first time,
# meaning that if we apply the time-of-day shader overlays to a scene after characters have already been added to the scene,
# those characters won't be tinted with the time-of-day colors until they are removed and re-added to the scene tree.
func retint_all_characters():
	var target_color = Color("fff")
	if Globals.time == "morning":
		target_color = Color("faa084")
	elif Globals.time == "night":
		target_color = Color("9999bc")

	for child in $Characters.get_children():
		if child is Character:
			var tween = get_tree().create_tween()
			tween.tween_property(child, "modulate", target_color, 0.5)


func change_scene(path, timing_overide=1.5):

	# In the case that this is called and told to change the scene to the same scene it's already on,
	# just do nothing.
	if current_scene_path == path:
		return

	# If the path is invalid, report an error and do nothing.
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("Error: Tried to change scene to invalid path: " + str(path))
		return
	
	if current_scene:
		if current_vignette:
			current_vignette.tween_opacity(1.0, 0.0, timing_overide)
		await get_tree().create_timer(timing_overide).timeout
		current_scene.queue_free()
	
	# make new scene
	var new_scene_resource = load(path) # maybe find a less laggy way to do this?
	var new_scene_instance = new_scene_resource.instantiate()
	add_child(new_scene_instance)
	current_scene = new_scene_instance
	current_scene_path = path

	# Ensures the correct shader overlays are applied to the new scene .
	apply_time_of_day_to_scene(current_scene, path)
	
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


# MANAGING THE INTRO TRANSITION
func intro_transition(step: int):
	#$Ripple.set_ripple_size(step)
	current_scene.intro_step(step)
	
	if step == 5: 
		current_scene = get_node("landscape")
		# Keeps scene bookkeeping in sync when we bypass change_scene.
		if current_scene and current_scene.scene_file_path != "":
			current_scene_path = current_scene.scene_file_path

		# Ensures the correct shader overlays are applied to the new scene.
		apply_time_of_day_to_scene(current_scene, current_scene_path)

		var new_vignette : Vignette = vignette.instantiate()
		
		current_vignette = new_vignette
		current_vignette.autoplay = false
		current_vignette.set_shader_value(1.0)
		current_scene.add_child(current_vignette)


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
		
func make_it_rain():
	# Avoid stacking multiple rain nodes if this is called repeatedly for the same scene.
	for child in current_scene.get_children():
		if child.scene_file_path == rain.resource_path:
			return
	var the_rain = rain.instantiate()
	current_scene.add_child(the_rain)

# Removes any existing rain instance from the current scene.
func remove_rain():
	if not current_scene:
		return
	for child in current_scene.get_children():
		if child.scene_file_path == rain.resource_path:
			child.queue_free()
