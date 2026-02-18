extends StaticBody3D

var isInteractable = true

var interactableText = "Press \"e\" to Mine Fossil"

@onready var rockCamera = $Camera3D
var playerCamera: Camera3D
var fossilCameraTargetPoint: Transform3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	playerCamera = get_tree().get_first_node_in_group("player_camera")
	fossilCameraTargetPoint = rockCamera.global_transform


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func interact():
	print("You interacted with the fossil!")
	enterRockCamera()

func enterRockCamera():
	rockCamera.global_transform = playerCamera.global_transform
	playerCamera.current = false
	rockCamera.make_current()
	var tween = create_tween()
	tween.tween_property(rockCamera, "global_transform", fossilCameraTargetPoint, 0.8)
	tween.set_ease(Tween.EASE_IN_OUT)
