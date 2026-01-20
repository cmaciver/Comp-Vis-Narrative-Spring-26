@tool
class_name LinkingButton
extends Button

@export var button_text : String = "default button text" :
	set(value):
		button_text = value
		$".".text = button_text


@export var link_destination : Slide



func _on_pressed() -> void:
	pass # Replace with function body.
	if link_destination:
		## TODO actually hide this one as well
		link_destination.visible = true
		
