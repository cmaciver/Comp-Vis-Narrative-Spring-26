extends CanvasLayer

@onready var stamina_bar: ProgressBar = $Control/StaminaBar

# Update the stamina bar; expects current in [0, max_val].
func set_stamina(current: float, max_val: float) -> void:
	if stamina_bar == null:
		return
	stamina_bar.max_value = max_val
	stamina_bar.value = clamp(current, 0.0, max_val)
