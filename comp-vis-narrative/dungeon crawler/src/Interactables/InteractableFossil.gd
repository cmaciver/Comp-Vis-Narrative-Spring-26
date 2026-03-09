extends Node3D

var isInteractable = true

var interactableText = "Press \"e\" to Mine Fossil"

@onready var clickable_sphere_scene = preload("res://dungeon crawler/src/Interactables/ClickableSphere.tscn")
@onready var fossil_collected_popup = preload("res://dungeon crawler/src/Interactables/UIFossilCollected.tscn")
@onready var field_log_popup = preload("res://dungeon crawler/src/ui/field_log.tscn")
@onready var fossil_item_scene = preload("res://dungeon crawler/src/Items/fossil_item.tscn")
@onready var reinforcement_scene = preload("res://dungeon crawler/src/Interactables/ReinforcementMinigame.tscn")
@export var fossil_scenes: Array[PackedScene]

@onready var rockCamera = $StaticBody3D/Camera3D

#the fossils description that gets filled on the field log for the fossil
@export var fossilDescription = "write a description"

var playerCamera: Camera3D
var fossilCameraTargetPoint: Transform3D
var dotsClicked: int

var fieldLog
var new_fossil

#the radius that the dots can spawn in front of the camera during interaction
@export var dotSpawnRadius: int = 300
@export var miningHitsRequired = 5

#used to select which fossil to give the player (global to give the popup menu the info)
var rand_idx: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rand_idx = randi_range(0, fossil_scenes.size() - 1)
	playerCamera = get_tree().get_first_node_in_group("player_camera")
	fossilCameraTargetPoint = rockCamera.global_transform
	dotsClicked = 0
	
func interact():
	# Lerp the sound effect to 0.25 to make it a little more quiet when in the fossil mining interaction
	var audio_manager = get_tree().root.get_node("Node3D/DungeonCrawlerAudioManager")
	if audio_manager and audio_manager.has_method("play_sound_effect"):
		audio_manager.fade_bgm_to_volume(0.15, 2.0)

	enterRockCamera()

func enterRockCamera():
	rockCamera.global_transform = playerCamera.global_transform
	rockCamera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	deactivatePlayer()
	
	#move the camera into the position in front of the rock (position for camera will probably be set for each rock)
	var tween = create_tween()
	tween.tween_property(rockCamera, "global_transform", fossilCameraTargetPoint, 0.8)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	#call the spawning spheres fucntion once the camera has fully moved into position
	tween.tween_callback(raycastAndSpawnClickableSpheres)
	
func deactivatePlayer():
	#disable player tree inputs
	playerCamera.current = false
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Zero their velocity and reset their motion state to prevent them from moving during the interaction 
		# which can cause the fossil breaks during the extraction sequence.
		if player.has_method("reset_motion_state"):
			player.reset_motion_state()
		elif "velocity" in player:
			player.velocity = Vector3.ZERO
		player.set_process_input(false)
		player.set_physics_process(false)
		player.hide()  # hides the mesh
		#disable crosshair (THIS BREAKS CLICKING IF NOT HIDDEN)
		var crosshair = player.get_node("Crosshair")
		if crosshair:
			crosshair.hide()
			
		#disable the interact text (so that the player doesn't see "interact" during the interaction)
		var canvas = player.get_node("CanvasLayer")
		if canvas:
			canvas.hide()
		# disable all collision shapes on the player (proably unnecessary)
		for child in player.get_children():
			if child is CollisionShape3D:
				child.disabled = true
	

func reactivatePlayer(initials: String, description: String):
	new_fossil.fieldLogInfo = {
		"initials": initials,
		"description": description
	}
	#now give the player the fossil to avvoid race conditions
	#new_fossil.interact()
	
	#move the camera back to the player
	var tween = create_tween()
	tween.tween_property(rockCamera, "global_transform", playerCamera.global_transform, 0.8)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_callback(reactivatePlayerFunctionality)

func reactivatePlayerFunctionality():
	#reenable player tree inputs
	playerCamera.make_current()
	rockCamera.current = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_process_input(true)
		player.set_physics_process(true)
		player.show()  # hides the mesh
		#disable crosshair (THIS BREAKS CLICKING IF NOT HIDDEN)
		var crosshair = player.get_node("Crosshair")
		if crosshair:
			crosshair.show()
			
		#disable the interact text (so that the player doesn't see "interact" during the interaction)
		var canvas = player.get_node("CanvasLayer")
		if canvas:
			canvas.show()
		# disable all collision shapes on the player (proably unnecessary)
		for child in player.get_children():
			if child is CollisionShape3D:
				child.disabled = false
		
		queue_free() #Free the interactable fossil
	
func raycastAndSpawnClickableSpheres():
	#create the ray from the camera and see where it collides with the rock
	var result = createAndCheckForRayCollision(dotSpawnRadius)
	
	#check for collision
	if(result):
		var sphere = clickable_sphere_scene.instantiate()
		get_tree().root.add_child(sphere)
		sphere.global_position = result.position
		
		#listen for the dot signal when the dot is clicked (will go to the dotClicked() method when the dot is clicked)
		sphere.dot_clicked.connect(dotClicked)
		
	#if the raycast doesn't hit the object, then raycast again
	else:
		raycastAndSpawnClickableSpheres()

#create a ray in a random direciton in front of the camera
#@param the radius in front of the camera that dots can spawn
#@return the intersection point that the ray hits the rock
func createAndCheckForRayCollision(spawnDotsRadius: int): 
	var space_state = get_world_3d().direct_space_state
	
	#getting users center of screen
	var viewport_size = get_viewport().get_visible_rect().size
	var random_X = randi_range(-1 * spawnDotsRadius, spawnDotsRadius)
	var random_Y = randi_range(-1 * spawnDotsRadius, spawnDotsRadius)
	var center = (viewport_size / 2) - Vector2(random_X , random_Y)
	var direction = rockCamera.project_ray_normal(center)
	
	var origin = rockCamera.global_position
	var end = origin + direction * 10
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	
	return space_state.intersect_ray(query)
	
#function activated after each dot is clicked
func dotClicked():
	# TODO camera shake?? could be fire...
	shake_camera()
	
	# TODO sound effect?? kickin rocks?? could be one hundred...
	
	dotsClicked += 1
	if(dotsClicked  >= miningHitsRequired):
		spawnReinforcementMinigame()
		#TODO Break the rock at the end of the interaction
		%FossilRock.hide() ###I WANT TO REPLACE THIS WITH SOME SORT OF ROCK BLOWING INTO MANY PIECES but doing this after MVP
		%RockCollision.hide()
		isInteractable = false
	else:
		
		raycastAndSpawnClickableSpheres()


func shake_camera(duration: float = 0.2, amount: float = 0.05, shakes: int = 3):
	var original_pos: Vector3 = %TargetCameraPoint.position
	
	var tween := get_tree().create_tween()
	for i in range(shakes):
		var offset = Vector3(
			randf_range(-amount, amount),
			randf_range(-amount, amount),
			randf_range(-amount, amount) # see if it should be 2D only? EDIT nah 3D is chill
		)
		# decrease the size of the shakes linearly
		offset *= float(shakes - i) / shakes 
		
		# adapted from https://github.com/EvilBunnyMan/TweenFX/blob/main/addons/TweenFX/TweenFX.gd
		tween.tween_property($StaticBody3D/Camera3D, "position", original_pos + offset, duration / (shakes * 2))
		tween.tween_property($StaticBody3D/Camera3D, "position", original_pos, duration / (shakes * 2))




func spawnReinforcementMinigame():
	var minigame = reinforcement_scene.instantiate()
	minigame.fossil_index = rand_idx
	get_tree().root.add_child(minigame)
	minigame.reinforcement_complete.connect(onReinforcementComplete)

func onReinforcementComplete():
	spawnFossilCollectedPopup()

func spawnFossilCollectedPopup():
	var popup = fossil_collected_popup.instantiate()
	get_tree().root.add_child(popup)
	popup.load_fossil(fossil_scenes[rand_idx].resource_path)
	
	#connect the popup closed to a function (weird syntax because it brings a parameter)
	popup.collection_screen_closed.connect(func(weight): harvestPopupClosed(weight))

func harvestPopupClosed(weight: int):
	# Once we put this item (safely so as to not cause any crashes) into the player's inventory, 
	# the code there will automatically calculate the new total weight and apply any stamina penalties based on that.

	# Items are added to the inventory by item reference with a function in the inventory script called add_item_to_inventory.
	# From an object oriented programming perspective, the Player object has an Inventory object as a child,
	# and the Inventory object has items as children of itself. The Inventory object is responsible for managing the items,
	# and the Player object can ask the Inventory to add/remove items as needed using the Inventory's public add_item_to_inventory/remove_item_from_inventory functions.
	# So to add the harvested item to the player's inventory, we need to get a reference to the player, 
	# then get a reference to their inventory, and then call the add_item_to_inventory function on that inventory with the harvested item as an argument.

	#this code is no longer needed now that we have a separate fossil item
	#var player = get_tree().get_first_node_in_group("player")
	#if player:
		#var inv = player.get_node_or_null("Inventory")
		#if inv and inv.has_method("add_item_to_inventory"):
			#inv.add_item_to_inventory(harvested_item, 1)
	
	print("You harvested " + str(weight) + " lbs")
	fieldLog = field_log_popup.instantiate()
	get_tree().root.add_child(fieldLog)
	fieldLog.updateDescription(fossilDescription)
	fieldLog.preparePopup()
	
	#Spawn our fossil item
	new_fossil = fossil_scenes[rand_idx].instantiate()
	new_fossil.fossilScenePath = fossil_scenes[rand_idx].resource_path
	new_fossil.weight = weight
	new_fossil.position = get_parent().position + Vector3(0.0, -0.2, 0.0)
	get_parent().get_parent().add_child(new_fossil) #this is ugly sorry
	#new_fossil.interact() #commented out because of race condition

	new_fossil.interact()
	fieldLog.log_screen_closed.connect(reactivatePlayer)

	# Lerp the sound effect to 0.5 to restore it back to normal after the interaction is over
	var audio_manager = get_tree().root.get_node("Node3D/DungeonCrawlerAudioManager")
	if audio_manager and audio_manager.has_method("play_sound_effect"):
		audio_manager.fade_bgm_to_volume(0.5, 1.0)
