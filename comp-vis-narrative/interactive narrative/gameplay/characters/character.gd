extends Sprite2D
class_name Character

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	modulate = Color(1, 1, 1, 0)
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.5)

# Fades the the thing out and queue frees it
func fade_out():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(self.queue_free)
