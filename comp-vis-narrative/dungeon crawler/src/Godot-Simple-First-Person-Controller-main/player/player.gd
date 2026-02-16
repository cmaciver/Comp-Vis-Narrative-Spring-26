extends CharacterBody3D

@export var footstep_sound: Array[AudioStream]

var run_speed = 5.5
var sprint_speed = 8.0
var speed = run_speed
var walk_speed = 3
var crouch_speed = 1.8

var jump_velocity = 7
var landing_velocity

var distance = 0
var footstep_distance = 2.1

# stamina values are in arbitrary units (0..max_stamina)
var max_stamina := 100.0
var stamina := max_stamina
var stamina_drain_rate := 25.0 # units per second while sprinting
var stamina_regen_rate := 15.0 # units per second while not sprinting
var stamina_reenable_threshold := 0.5 # fraction of max to reenable sprint
var can_sprint := stamina >= max_stamina * stamina_reenable_threshold # whether the player is currently allowed to sprint (i.e. has enough stamina)

var fossilsCollected = 0
var fossilsReturned = 0

#@export var voxel_terrain : VoxelTerrain
#@onready var voxel_tool : VoxelTool = voxel_terrain.get_voxel_tool()

@export var hud_path: NodePath
@onready var hud: CanvasLayer = get_node_or_null(hud_path)

@onready var marker = $HeadPosition/LandingAnimation/Camera3D/DigMarker

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_resolve_hud()
	_update_stamina_bar()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x / 10
		%Camera3D.rotation_degrees.x -= event.relative.y / 10
		%Camera3D.rotation_degrees.x = clamp(%Camera3D.rotation_degrees.x, -90, 90)


func _physics_process(delta: float) -> void:
	
	# The code for raycasting to detect if an object is in front of the player is interactable
	%InteractText.hide()
	if %SeeCast.is_colliding():
		var target = %SeeCast.get_collider()
		if target != null and target.has_method("interact") and target.isInteractable:
			%InteractText.text = target.interactableText
			%InteractText.show()
			if Input.is_key_pressed(KEY_E):
				target.interact()
	
	if not is_on_floor():
		velocity += get_gravity() * 2 * delta
		landing_velocity = -velocity.y
		distance = 0

	# Jump with Space - only if on floor and no ceiling above
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor() and not $CeilingDetector.is_colliding():
		velocity.y = jump_velocity
		play_random_footstep_sound()

	if not $CeilingDetector.is_colliding():
		$CollisionShape3D.shape.height = lerp($CollisionShape3D.shape.height, 1.85, 0.1)
	else:
		$CollisionShape3D.shape.height = lerp($CollisionShape3D.shape.height, 1.38, 0.1)

	if is_on_floor():
		if landing_velocity != 0:
			landing_animation()
			landing_velocity = 0

		speed = run_speed
		# Crouch with C key.
		# Slow walk with Ctrl key.
		# Sprint with Shift key (only if can_sprint and has stamina).
		var wants_crouch = Input.is_key_pressed(KEY_C)
		var wants_slow_walk = Input.is_key_pressed(KEY_CTRL)
		var wants_sprint = Input.is_key_pressed(KEY_SHIFT)

		# crouch overrides other movement speeds
		if wants_crouch:
			speed = crouch_speed
		elif wants_slow_walk:
			speed = walk_speed
		elif wants_sprint and can_sprint and stamina > 0.0:
			speed = sprint_speed
			sprint(true, delta)
		else:
			sprint(false, delta)
	else:
		sprint(false, delta)

	if Input.is_key_pressed(KEY_C):
		$CollisionShape3D.shape.height = lerp($CollisionShape3D.shape.height, 1.38, 0.1)

	$MeshInstance3D.mesh.height = $CollisionShape3D.shape.height
	%HeadPosition.position.y = $CollisionShape3D.shape.height - 0.25

	# Movement inputs
	var input_dir = Vector2.ZERO
	# Forward (W or Z)
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_Z):
		input_dir.y -= 1
	# Backward (S)
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	# Left (A or Q)
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_Q):
		input_dir.x -= 1
	# Right (D)
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	distance += get_real_velocity().length() * delta

	if distance >= footstep_distance:
		distance = 0
		if speed > walk_speed:
			play_random_footstep_sound()

	move_and_slide()


	# digging code
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		pass
		# voxel_tool.mode = VoxelTool.MODE_REMOVE
		# voxel_tool.do_sphere(marker.global_position, 2.0)
		
		#voxel_terrain.save_modified_blocks()
		

func landing_animation():
	if landing_velocity >= 2:
		play_random_footstep_sound()

	var tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
	var amplitude = clamp(landing_velocity / 100, 0.0, 0.3)

	tween.tween_property(%LandingAnimation, "position:y", -amplitude, amplitude)
	tween.tween_property(%LandingAnimation, "position:y", 0, amplitude)


func play_random_footstep_sound() -> void:
	if footstep_sound.size() > 0:
		$FootstepSound.stream = footstep_sound.pick_random()
		$FootstepSound.play()

## Handles sprinting logic, including stamina drain and regeneration. Should be called every frame with the current sprinting state and delta time.
## [br]
## **param** active Whether the player is currently trying to sprint.
## [br]
## **param** delta The time in seconds since the last frame, used to calculate stamina changes
func sprint(active: bool, delta: float) -> void:
	# If sprinting is active and allowed, drain stamina. 
	if active and can_sprint:
		# Drain stamina based on the defined rate and time elapsed.
		# By using a constant here it's much easier to adjust the stamina system.
		stamina -= stamina_drain_rate * delta

		# If the player fully depletes their stamina, 
		# we disable sprinting until they regenerate enough to reenable it.
		if stamina <= 0.0:
			stamina = 0.0
			can_sprint = false
	else:
		# If the player is either not trying to sprint or is not allowed to sprint, we regenerate stamina.
		stamina += stamina_regen_rate * delta
		# Rather than let players immediately be able to sprint again after regenerating any epsilon > 0
		# amount of stamina, we require them to regenerate to a certain threshold (e.g. 50% of max) before re-enabling sprinting.
		# This prevents a rubber-bandy looking experience where players could theoretically sprint for a few frames,
		# stop for a few frames to regenerate a tiny bit of stamina, then sprint again, repeatedly.
		if not can_sprint and stamina >= max_stamina * stamina_reenable_threshold:
			can_sprint = true

	# Ensure stamina stays within valid bounds.
	stamina = clamp(stamina, 0.0, max_stamina)

	# Updates the stamina bar in the UI to reflect the current stamina value after changes.
	_update_stamina_bar()


## Updates the stamina bar UI element to reflect the current stamina and max stamina values.
func _update_stamina_bar() -> void:
	# If we don't have a reference to the HUD, try to resolve it. 
	# This allows the stamina bar to update correctly even if the 
	# HUD wasn't immediately available when the player node was initialized.
	if not hud:
		_resolve_hud()

	# If we have a valid HUD reference and it has the set_stamina method,
	# call it to safely update the stamina bar display with the current stamina values.
	# We pass the can_sprint value as well so the HUD can adjust visuals accordingly 
	# (e.g. flashing and color change when sprinting is disabled).
	if hud and hud.has_method("set_stamina"):
		hud.set_stamina(stamina, max_stamina, can_sprint)

## Attempts to resolve the HUD node reference if it hasn't been set yet.
## This will look for the node at the specified hud_path and assign it to the hud variable.
func _resolve_hud() -> void:
	if hud_path != NodePath(""):
		hud = get_node_or_null(hud_path)
