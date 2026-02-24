extends RigidBody3D

var isInteractable = true
var interactableText = "Press \"e\" to pick up"
@onready var player = get_tree().root.get_node("Node3D/Player")

func interact():
	if player != null:
		reparent(player)
		gravity_scale = 0.0
		rotation = Vector3(0.0, 0.0, 0.0)
		isInteractable = false
		freeze = true
		collision_layer = 2
		global_position = player.get_node("HeadPosition/LandingAnimation/Camera3D/HoldingLocation").global_position
		player.is_holding = self

func drop():
	reparent(get_tree().root.get_node("Node3D/dc_terrain"))
	gravity_scale = 1.0
	isInteractable = true
	freeze = false
	collision_layer = 1
	position -= player.global_transform.basis.z * 1.25
	
