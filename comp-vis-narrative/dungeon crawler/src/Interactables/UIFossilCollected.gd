extends Control

signal collection_screen_closed(weight: float)

#variable for fossil rotation
@export var rotationSpeed: Vector3 = Vector3(0,50,0)

#variables for fossil backlighting changes
var lightCycleSpeed = 0.25
var light_color = 0.0

#variables for the randomly selected fossil weight
var randomWeight = randi_range(50, 150)
var prevWeight = 0
var userCanExitPage = false

var displayedFossil

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#move offscreen for the shifting function
	position = Vector2(0, get_viewport_rect().size.y)
	moveIntoScreen()
	
	#have title pulsate
	animatePrimaryTitle()
	
	#the weight counts up
	animateWeightCountup()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#logic hanlding the rotation of the fossil
	if displayedFossil:
		displayedFossil.rotation_degrees += rotationSpeed * delta
	#%FossilMesh.rotation_degrees += rotationSpeed * delta
	
	#Logic handling the backlighting of the fossil changing
	light_color += delta * lightCycleSpeed
	light_color = fmod(light_color, 1.0)
	%FossilLight.light_color = Color.from_ok_hsl(light_color, 1.0, 0.5, 1.0)

func load_fossil(path: String):
	var viewport = $ColorRect/SubViewportContainer/SubViewport

	# Load and add the new one
	var fossil_scene = load(path)
	var fossil = fossil_scene.instantiate()
	viewport.add_child(fossil)
	#rotate so that it faces the camera better
	#fossil.rotate_x(deg_to_rad(90))
	
	fossil.gravity_scale = 0
	fossil.freeze = true
	displayedFossil = fossil

func moveIntoScreen():
	var tween = create_tween()
	tween.set_ease(tween.EASE_OUT)
	tween.set_trans(tween.TRANS_QUINT)
	tween.tween_property(self, "position", Vector2(0, 0), 2.0)

func animatePrimaryTitle():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(%PrimaryTitle, "theme_override_font_sizes/font_size", 72, 1.0)
	tween.tween_property(%PrimaryTitle, "theme_override_font_sizes/font_size", 56, 1.0)
	
func animateWeightCountup():
	total_times_called = 0
	last_time_sound_played = -10
	
	var tween = create_tween()
	tween.tween_interval(1.0)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_method(updateWeightLabel, 0, randomWeight, 3.0)
	
	#when it is done allow the user to click to continue
	tween.tween_callback(updateWeightFinished)

# very temp very hacky persistant variable for tracking how many times this function has been called
var total_times_called = 0
var last_time_sound_played = -10
func updateWeightLabel(value: float):
	%WeightTitle.text = "+ " + str(snappedi(value, 1)) + " lbs"
	
	if prevWeight != value and total_times_called - last_time_sound_played > 2:
		$WeightTickSFX.pitch_scale += 0.02
		$WeightTickSFX.play()
		last_time_sound_played = total_times_called
		

	prevWeight = value
	total_times_called += 1

func updateWeightFinished():
	userCanExitPage = true


func _on_gui_input(event: InputEvent) -> void:
	if(event is InputEventMouseButton and userCanExitPage):
		emit_signal("collection_screen_closed", randomWeight)
		queue_free()
