extends RigidBody3D

var isInteractable = true
var interactableText = "Press \"e\" to pick up"
@onready var fossil_res = preload("res://dungeon crawler/src/Items/fossil.tres")
@onready var player = get_tree().root.get_node("Node3D/Player")

var weight = 0

func _ready() -> void:
	fossil_res.weight = weight

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
		
		var inv = player.get_node_or_null("Inventory")
		if inv and inv.has_method("add_item_to_inventory"):
			inv.add_item_to_inventory(fossil_res, 1)

func drop():
	reparent(get_tree().root.get_node("Node3D/dc_terrain"))
	gravity_scale = 1.0
	isInteractable = true
	freeze = false
	collision_layer = 1
	position -= player.global_transform.basis.z * 1.25
	
	var inv = player.get_node_or_null("Inventory")
	if inv and inv.has_method("remove_item_from_inventory"):
		inv.remove_item_from_inventory("0", 1)
	
