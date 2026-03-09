extends Control

signal reinforcement_complete

@export var num_cracks: int = 1
@export var completion_threshold: float = 0.98
@export var brush_radius: int = 12  # pixels to erase per frame
@export var max_crack_scale: float = 0.4
@export var min_crack_scale: float = 0.15
@export var crack_scale_step: float = 0.05

@onready var crack_overlay_scene = preload("res://dungeon crawler/src/Interactables/CrackOverlay.tscn")

var fossil_index: int = 0
var white_pixels: Array = []

# Fossil background images (order must match fossil_scenes array on InteractableFossil)
var fossil_backgrounds = [
	preload("res://dungeon crawler/src/assets/reinforcement/fossil_trex_arm.png"),
	preload("res://dungeon crawler/src/assets/reinforcement/fossil_trex_foot_bone.png"),
	preload("res://dungeon crawler/src/assets/reinforcement/fossil_trex_tooth.png"),
	preload("res://dungeon crawler/src/assets/reinforcement/fossil_trike_jaw.png"),
	preload("res://dungeon crawler/src/assets/reinforcement/fossil_trike_skull.png"),
	preload("res://dungeon crawler/src/assets/reinforcement/fossil_turtle_arm.png"),
]

# Masks (white = bone, black = background), same order as fossil_backgrounds
var fossil_masks = [
	preload("res://dungeon crawler/src/assets/reinforcement/fossil_trex_arm_mask.png"),
	preload("res://dungeon crawler/src/assets/reinforcement/fossil_trex_foot_bone_mask.png"),
	preload("res://dungeon crawler/src/assets/reinforcement/fossil_trex_tooth_mask.png"),
	preload("res://dungeon crawler/src/assets/reinforcement/fossil_trike_jaw_mask.png"),
	preload("res://dungeon crawler/src/assets/reinforcement/fossil_trike_skull_mask.png"),
	preload("res://dungeon crawler/src/assets/reinforcement/fossil_turtle_arm_mask.png"),
]

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
	%FossilImage.texture = fossil_backgrounds[fossil_index]

	# Precompute white pixels from mask
	var mask_image = fossil_masks[fossil_index].get_image()
	for x in range(mask_image.get_width()):
		for y in range(mask_image.get_height()):
			if mask_image.get_pixel(x, y).r > 0.5:
				white_pixels.append(Vector2(x, y))

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
	var mask_image = fossil_masks[fossil_index].get_image()
	var mask_size = Vector2(mask_image.get_width(), mask_image.get_height())

	for i in num_cracks:
		var pair = crack_textures[randi() % crack_textures.size()]
		var crack_tex_size = pair[0].get_size()

		var chosen_pos = Vector2.ZERO
		var chosen_scale = max_crack_scale
		var placed = false

		for _attempt in range(50):
			# Pick a random white pixel and convert to UI coordinates
			var pixel = white_pixels[randi() % white_pixels.size()]
			var pos = Vector2(
				pixel.x / mask_size.x * fossil_rect.size.x,
				pixel.y / mask_size.y * fossil_rect.size.y
			)

			var scale = max_crack_scale
			while scale >= min_crack_scale:
				# Use half-diagonal as radius to account for any rotation
				var half_diag = crack_tex_size.length() * scale / 2
				# Sample 8 points around center at half-diagonal radius
				var fits = true
				for a in [0.0, PI/4, PI/2, 3*PI/4, PI, 5*PI/4, 3*PI/2, 7*PI/4]:
					var check = pos + Vector2(cos(a), sin(a)) * half_diag
					var mx = int(clamp(check.x / fossil_rect.size.x * mask_size.x, 0, mask_size.x - 1))
					var my = int(clamp(check.y / fossil_rect.size.y * mask_size.y, 0, mask_size.y - 1))
					if mask_image.get_pixel(mx, my).r < 0.5:
						fits = false
						break
				if fits:
					chosen_pos = pos
					chosen_scale = scale
					placed = true
					break
				scale -= crack_scale_step

			if placed:
				break

		# Fallback: place at center of white area at min scale
		if not placed:
			var pixel = white_pixels[white_pixels.size() / 2]
			chosen_pos = Vector2(
				pixel.x / mask_size.x * fossil_rect.size.x,
				pixel.y / mask_size.y * fossil_rect.size.y
			)
			chosen_scale = min_crack_scale

		var crack = crack_overlay_scene.instantiate()
		crack.damaged_texture = pair[0]
		crack.healed_texture = pair[1]
		%CracksContainer.add_child(crack)
		crack.scale = Vector2(chosen_scale, chosen_scale)
		crack.position = chosen_pos
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
	reinforcement_complete.emit()
	queue_free()
