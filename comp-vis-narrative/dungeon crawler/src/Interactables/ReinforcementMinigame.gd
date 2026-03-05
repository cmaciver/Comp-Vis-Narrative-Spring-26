extends Control

signal reinforcement_complete

@export var num_cracks: int = 6
@export var completion_threshold: float = 0.90
@export var brush_radius: int = 12  # pixels to erase per frame

@onready var crack_overlay_scene = preload("res://dungeon crawler/src/Interactables/CrackOverlay.tscn")

var cracks: Array = []
var is_painting: bool = false
var minigame_complete: bool = false
var ready_to_paint: bool = false

func _ready():
	# Start offscreen and animate in
	position = Vector2(0, get_viewport_rect().size.y)
	move_into_screen()
	# Delay crack spawning to let the screen animate in first
	await get_tree().create_timer(0.5).timeout
	spawn_cracks()

func move_into_screen():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "position", Vector2.ZERO, 1.0)

func spawn_cracks():
	var fossil_rect = %FossilImage.get_rect()
	for i in num_cracks:
		var crack = crack_overlay_scene.instantiate()
		%CracksContainer.add_child(crack)
		# Random position within fossil bounds
		crack.position = Vector2(
			randf_range(40, fossil_rect.size.x - 40),
			randf_range(40, fossil_rect.size.y - 40)
		)
		crack.rotation = randf_range(-PI / 3, PI / 3)
		cracks.append(crack)

	# Wait for cracks to initialize (they use await internally)
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
	for crack in cracks:
		if crack.has_method("get_coverage"):
			total += crack.get_coverage()

	var progress = total / max(cracks.size(), 1)
	%ProgressBar.value = progress * 100
	%ProgressLabel.text = "Glue Progress: %d%%" % int(progress * 100)

	if progress >= completion_threshold and not minigame_complete:
		complete_minigame()

func complete_minigame():
	minigame_complete = true

	# White flash jacket overlay
	var jacket = ColorRect.new()
	jacket.color = Color.WHITE
	jacket.set_anchors_preset(Control.PRESET_FULL_RECT)
	jacket.modulate.a = 0
	add_child(jacket)

	var tween = create_tween()
	tween.tween_property(jacket, "modulate:a", 0.85, 0.4)
	tween.tween_interval(0.6)
	tween.tween_callback(func():
		reinforcement_complete.emit()
		queue_free()
	)
