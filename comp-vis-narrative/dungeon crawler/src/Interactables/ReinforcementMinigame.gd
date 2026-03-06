extends Control

signal reinforcement_complete

@export var num_cracks: int = 1
@export var completion_threshold: float = 0.98
@export var brush_radius: int = 12  # pixels to erase per frame
@export var crack_scale: float = 0.4  # Scale down crack images

@onready var crack_overlay_scene = preload("res://dungeon crawler/src/Interactables/CrackOverlay.tscn")

# Crack texture pairs (damaged, healed)
var crack_textures = [
	[
		preload("res://dungeon crawler/src/assets/reinforcement/crack_1.png"),
		preload("res://dungeon crawler/src/assets/reinforcement/crack_1_glued.png")
	],
	[
		preload("res://dungeon crawler/src/assets/reinforcement/crack_2.png"),
		preload("res://dungeon crawler/src/assets/reinforcement/crack_2_glued.png")
	],
	[
		preload("res://dungeon crawler/src/assets/reinforcement/crack_3_updated.png"),
		preload("res://dungeon crawler/src/assets/reinforcement/crack_3_glued_updated.png")
	]
]

var cracks: Array = []
var is_painting: bool = false
var minigame_complete: bool = false
var ready_to_paint: bool = false

func _ready():
	# Hide repair UI initially
	%FossilContainer.modulate.a = 0
	%ProgressContainer.modulate.a = 0
	%InstructionLabel.modulate.a = 0

	# Start offscreen and animate in
	position = Vector2(0, get_viewport_rect().size.y)
	move_into_screen()

func move_into_screen():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "position", Vector2.ZERO, 1.0)
	tween.tween_callback(show_discovery_text)

func show_discovery_text():
	# Discovery title is already visible from sliding up, just hold then transition
	var tween = create_tween()
	tween.tween_interval(1.5)  # Hold for a moment
	tween.tween_callback(transition_to_repair)

func transition_to_repair():
	var tween = create_tween()
	tween.set_parallel(true)
	# Fade out discovery title
	tween.tween_property(%DiscoveryTitle, "modulate:a", 0.0, 0.4)
	# Fade in repair UI
	tween.tween_property(%FossilContainer, "modulate:a", 1.0, 0.4)
	tween.tween_property(%ProgressContainer, "modulate:a", 1.0, 0.4)
	tween.tween_property(%InstructionLabel, "modulate:a", 1.0, 0.4)

	tween.set_parallel(false)
	tween.tween_callback(spawn_cracks)

func spawn_cracks():
	var fossil_rect = %FossilImage.get_rect()
	for i in num_cracks:
		# Pick a random crack texture pair
		var pair = crack_textures[randi() % crack_textures.size()]

		var crack = crack_overlay_scene.instantiate()
		crack.damaged_texture = pair[0]
		crack.healed_texture = pair[1]
		%CracksContainer.add_child(crack)

		# Scale down the crack
		crack.scale = Vector2(crack_scale, crack_scale)

		# Calculate safe bounds based on scaled crack size
		# Add extra padding for rotation (rotated rect has larger bounding box)
		var crack_size = pair[0].get_size() * crack_scale
		var max_dimension = max(crack_size.x, crack_size.y)
		var margin = Vector2(max_dimension, max_dimension) * 0.7  # Use larger dimension + buffer
		crack.position = Vector2(
			randf_range(margin.x, fossil_rect.size.x - margin.x),
			randf_range(margin.y, fossil_rect.size.y - margin.y)
		)
		crack.rotation = randf_range(-PI / 3, PI / 3)
		cracks.append(crack)

	# Wait for cracks to initialize
	await get_tree().create_timer(0.2).timeout
	ready_to_paint = true

func _input(event):
	if minigame_complete or not ready_to_paint:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_painting = event.pressed
		if event.pressed:
			erase_at(event.position)

	if event is InputEventMouseMotion and is_painting:
		erase_at(event.position)

func erase_at(global_pos: Vector2):
	for crack in cracks:
		if crack.has_method("erase_at_global"):
			crack.erase_at_global(global_pos, brush_radius)
	update_progress()

func update_progress():
	var total = 0.0
	var all_complete = true
	for crack in cracks:
		if crack.has_method("get_coverage"):
			total += crack.get_coverage()
			if crack.get_coverage() < completion_threshold:
				all_complete = false

	var progress = total / max(cracks.size(), 1)
	%ProgressBar.value = progress * 100
	%ProgressLabel.text = "Consolidant: %d%%" % int(progress * 100)

	if all_complete and not minigame_complete:
		%ProgressBar.value = 100
		%ProgressLabel.text = "Consolidant: %d%%" % 100
		complete_minigame()

func complete_minigame():
	minigame_complete = true

	# Update instruction text
	%InstructionLabel.text = "Jacketing fossil..."

	# Start the burlap strip animation
	animate_jacketing()

func animate_jacketing():
	var fossil_rect = %FossilImage.get_rect()

	# Burlap strip settings
	var num_strips = 6
	var strip_width = fossil_rect.size.x * 0.35
	var strip_height = fossil_rect.size.y * 1.2
	var strip_color = Color(0.95, 0.93, 0.88, 0.92)

	# Center-out placement order: center first, then alternate left/right
	# Indices represent order of placement, values are x-position multipliers (0=left, 1=right)
	var placement_order = [0.5, 0.25, 0.75, 0.0, 1.0, 0.5]  # center, left, right, far left, far right, center overlay
	var directions = ["top", "left", "right", "left", "right", "top"]  # Where each strip comes from

	var tween = create_tween()
	var strips_since_pause = 0

	for i in num_strips:
		var strip = ColorRect.new()
		strip.color = strip_color
		strip.size = Vector2(strip_width, strip_height)
		strip.pivot_offset = strip.size / 2  # Pivot at center for rotation and scale

		# Target position based on placement order (center-out with overlap)
		var x_mult = placement_order[i]
		var target_x = x_mult * (fossil_rect.size.x - strip_width * 0.3) + strip_width * 0.15 - strip_width / 2
		var target_y = fossil_rect.size.y / 2 - strip_height / 2

		# Slight rotation for natural look
		strip.rotation = randf_range(-0.15, 0.15)

		# Starting position based on direction
		var start_offset = Vector2.ZERO
		var direction = directions[i]
		match direction:
			"top":
				start_offset = Vector2(0, -120)
			"left":
				start_offset = Vector2(-100, -60)
			"right":
				start_offset = Vector2(100, -60)

		strip.position = Vector2(target_x, target_y) + start_offset
		strip.modulate.a = 0
		strip.scale = Vector2(1, 1)

		%FossilContainer.add_child(strip)

		# Determine if this is the "slide and tuck" strip (one in the middle)
		var is_slow_strip = (i == 3)
		var travel_time = 0.5 if is_slow_strip else 0.25

		# Beat 1: Fast travel to position + fade in
		tween.tween_property(strip, "position", Vector2(target_x, target_y), travel_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(strip, "modulate:a", strip_color.a, travel_time * 0.7)

		# Beat 2: Press/squish effect - compress Y then bounce back
		tween.tween_property(strip, "scale:y", 0.95, 0.08).set_ease(Tween.EASE_OUT)
		tween.tween_property(strip, "scale:y", 1.0, 0.10).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)

		# Rhythm: base stagger with longer pauses every 2-3 strips
		strips_since_pause += 1
		if strips_since_pause >= 2 and i < num_strips - 1 and randf() > 0.4:
			tween.tween_interval(randf_range(0.35, 0.45))  # Reaching for next piece
			strips_since_pause = 0
		else:
			tween.tween_interval(0.14)

	# After all strips placed, brief pause then transition
	tween.tween_interval(0.5)
	tween.tween_callback(finish_jacketing)

func finish_jacketing():
	# Final white overlay fade
	var jacket = ColorRect.new()
	jacket.color = Color.WHITE
	jacket.set_anchors_preset(Control.PRESET_FULL_RECT)
	jacket.modulate.a = 0
	add_child(jacket)

	var tween = create_tween()
	tween.tween_property(jacket, "modulate:a", 1.0, 0.4)
	tween.tween_callback(finish_and_transition)

func finish_and_transition():
	reinforcement_complete.emit()
	queue_free()
