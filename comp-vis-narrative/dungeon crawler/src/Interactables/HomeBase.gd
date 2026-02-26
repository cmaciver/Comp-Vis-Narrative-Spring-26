extends Area3D

@export var victory_label: Label  # assign in Inspector
	
func _on_body_entered(body):
	print("intersection :)")
	if body.is_in_group("player") && body.is_holding != null:
			body.is_holding.queue_free()
			body.is_holding = null
			show_victory_message()

func show_victory_message():
	if victory_label:
		victory_label.text = "🦕 Fossil secured! Great find, paleontologist!"
		victory_label.visible = true
		# Hide it after 3 seconds
		await get_tree().create_timer(3.0).timeout
		victory_label.visible = false
		
