extends StaticBody3D

var isInteractable = true

var interactableText = "Press \"e\" to Mine Fossil"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func interact():
	print("You interacted with the fossil!")
	queue_free()
