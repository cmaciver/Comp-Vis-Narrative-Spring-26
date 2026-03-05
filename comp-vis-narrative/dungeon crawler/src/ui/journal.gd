extends Control

@onready var slot_a = $ColorRect/JournalA
@onready var slot_b = $ColorRect/JournalB
@onready var right_button = $ColorRect/RightButton
@onready var left_button = $ColorRect/LeftButton
@onready var no_fossil_found_box = $ColorRect/NoFossilsFoundBox

var current_index = 0
var is_animating = false
var active_slot
var incoming_slot

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	active_slot = slot_a
	incoming_slot = slot_b
	
	# Hide the incoming slot off screen
	incoming_slot.position.x = size.x
	
	if DungeonCrawlerData.collectedLogs.size() == 0:
		active_slot.hide()
		incoming_slot.hide()
		left_button.hide()
		right_button.hide()
		no_fossil_found_box.show()
		return
	
	no_fossil_found_box.hide()
	
	loadEntryInto(active_slot, 0)
	update_buttons()

func loadEntryInto(slot, index: int):
	slot.load_entry(DungeonCrawlerData.collectedLogs[index], index)
	
func update_buttons():
	#disable and hide the left arrow at index 0
	if current_index == 0:
		left_button.hide()
		left_button.disabled = true
	else:
		left_button.show()
		left_button.disabled = false
	
	#disable and hide the right arrow at index size - 1
	if current_index == DungeonCrawlerData.collectedLogs.size() - 1:
		right_button.hide()
		right_button.disabled = true
	else:
		right_button.show()
		right_button.disabled = false
	#left_button.disabled = current_index == 0
	#right_button.disabled = current_index == DungeonCrawlerData.collectedLogs.size()

#moving the journals off and onto the screen
func navigate(direction: int):
	if is_animating:
		return
	
	var new_index = current_index + direction
	if new_index < 0 or new_index >= DungeonCrawlerData.collectedLogs.size():
		return
	
	is_animating = true
	current_index = new_index
	
	#bring the incoming slot into the screen from the correct direction
	incoming_slot.position.x = size.x * direction
	incoming_slot.show()
	loadEntryInto(incoming_slot, current_index)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(active_slot, "position:x", -size.x * direction, 0.4)
	tween.tween_property(incoming_slot, "position:x", 0.0, 0.4)
	await tween.finished
	
	#swap the slots to what is currently being displayed
	var temp = active_slot
	active_slot = incoming_slot
	incoming_slot = temp
	
	update_buttons()
	is_animating = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_right_button_pressed() -> void:
	navigate(1)


func _on_left_button_pressed() -> void:
	navigate(-1)
