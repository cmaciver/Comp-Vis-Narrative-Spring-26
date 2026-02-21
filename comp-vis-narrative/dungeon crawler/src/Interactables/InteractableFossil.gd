extends StaticBody3D

var isInteractable = true

var interactableText = "Press \"e\" to Mine Fossil"

@onready var clickable_sphere_scene = preload("res://dungeon crawler/src/Interactables/ClickableSphere.tscn")

@onready var rockCamera = $Camera3D
var playerCamera: Camera3D
var fossilCameraTargetPoint: Transform3D
var dotsClicked: int

#the radius that the dots can spawn in front of the camera during interaction
@export var dotSpawnRadius: int = 300

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	playerCamera = get_tree().get_first_node_in_group("player_camera")
	fossilCameraTargetPoint = rockCamera.global_transform
	dotsClicked = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func interact():
	print("You interacted with the fossil!")
	enterRockCamera()
	#raycastAndSpawnClickableSpheres()

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
	dotsClicked += 1
	print(dotsClicked)
	raycastAndSpawnClickableSpheres()
