extends RigidBody3D

var isInteractable = true
var interactableText = "Press \"e\" to pick up"
@onready var fossil_res = preload("res://dungeon crawler/src/Items/fossil.tres")
@onready var player

var weight = 0.0
var health = 100.0
@export var min_damage_speed := 4.0 # Threshold speed before collisions cause damage
@export var damage_per_speed := 1.0 # Damage multiplier per unit of impact speed

func _ready() -> void:
	# Enable contact reporting so we can read contact data in _integrate_forces.
	# https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html#class-rigidbody3d-property-contact-monitor
	contact_monitor = true
	# https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html#class-rigidbody3d-property-max-contacts-reported
	max_contacts_reported = 8
	fossil_res.weight = weight
	player = get_tree().root.get_node("Node3D/Player")

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

func drop() -> bool:
	var cast = player.get_node("HeadPosition/LandingAnimation/Camera3D/SeeCast")
	var collider = cast.get_collider()
	if collider == null: #this check isn't perfect but it's better than nothing
		reparent(get_tree().root.get_node("Node3D/dc_terrain"))
		gravity_scale = 1.0
		isInteractable = true
		freeze = false
		collision_layer = 1
		position -= player.global_transform.basis.z * 1.25
		
		var inv = player.get_node_or_null("Inventory")
		if inv and inv.has_method("remove_item_from_inventory"):
			inv.remove_item_from_inventory("0", 1)
		
		return true
	return false

# https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html#class-rigidbody3d-private-method-integrate-forces
# This function is called during the physics step and allows us to read contact data to implement custom collision responses, 
# in this case applying damage based on impact speed.

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# https://docs.godotengine.org/en/stable/classes/class_physicsdirectbodystate3d.html#class-physicsdirectbodystate3d-method-get-contact-count
	# Returns the number of contacts (collisions) currently involving this body. 
	var contact_count := state.get_contact_count()
	if contact_count == 0:
		# No contacts, so nothing to process.
		return

	# Keeps track of which contact had the highest relative speed, so we can apply damage based on that.
	# We don't sum damage across contacts because that leads to a lot more damage than might be expected by the player,
	# who from their perspective might have just hit one thing, not multiple things at once. 
	var max_speed := 0.0
	for i in contact_count:
		# https://docs.godotengine.org/en/stable/classes/class_physicsdirectbodystate3d.html#class-physicsdirectbodystate3d-method-get-contact-local-velocity-at-position
		# Returns the relative velocity at the contact point in local space. 
		# This is the velocity of the other body relative to this one.
		var rel_vel := state.get_contact_local_velocity_at_position(i)
		max_speed = max(max_speed, rel_vel.length())

	# We only apply damage if the impact speed exceeds our threshold, 
	# so stuff like just leaving the fossil on the ground or gently placing it down doesn't cause damage.
	if max_speed >= min_damage_speed:
		print("Applying damage from impact. Impact speed: ", max_speed, ", Health before: ", health)
		# We calculate damage as a linear function of how much the impact speed exceeds the threshold, multiplied by our damage multiplier.
		# This is opposed to calculating it as max_speed * damage_per_speed, as that would mean anything barely above the threshold could cause a lot of damage
		# if the threshold is high enough, while something barely below the threshold would cause no damage at all, which could be frustrating.
		health -= (max_speed - min_damage_speed) * damage_per_speed
	
