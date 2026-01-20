@tool
class_name Slide
extends Node2D

@onready var body = $CenterContainer/VBoxContainer/BodyText
@onready var options = $CenterContainer/VBoxContainer/Options

@export var body_text : String = "default body text" :
	set(value):
		body_text = value
		if body:
			body.text = value

var real_option_list : Array[LinkingButton] = []
@export var option_list : Dictionary[String, Slide] = {"default" : null}

@export_tool_button("Update Option", "Callable") var update_action = update_options
func update_options():
	print("updating options") ## TODO remove
	for x in real_option_list:
		x.queue_free()
	
	for key in option_list:
		var button = LinkingButton.new()
		button.text = key
		button.link_destination = option_list[key]
		options.add_child(button)
		button.owner = options


func _ready() -> void:
	if not Engine.is_editor_hint():
		update_options()
