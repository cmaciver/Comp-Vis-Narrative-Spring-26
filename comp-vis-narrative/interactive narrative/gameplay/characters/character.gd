extends Sprite2D
class_name Character

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	modulate = Color(1, 1, 1, 0)
	
	var target_color = Color("fff")
	if not Globals.in_cave:
		if Globals.time == "morning":
			target_color = Color("faa084")
		
		if Globals.time == "night":
			target_color = Color("9999bc")
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", target_color, 0.5)

# Fades the the thing out and queue frees it
func fade_out():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.5)
	tween.tween_callback(self.queue_free)
