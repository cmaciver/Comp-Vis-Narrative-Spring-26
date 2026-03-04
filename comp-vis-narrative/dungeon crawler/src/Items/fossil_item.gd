extends RigidBody3D

var isInteractable = true
var interactableText = "Press \"e\" to pick up"
@onready var fossil_res = preload("res://dungeon crawler/src/Items/fossil.tres")
@onready var player
@onready var camera_path := NodePath("HeadPosition/LandingAnimation/Camera3D")

# Distances in cylindrical coordinates relative to the player
# to use when positioning the fossil while it's being held. 
@export var hold_distance := 1.0
@export var hold_height := 1.0

# Keeps track of the camera's yaw angle (theta) for positioning the fossil while held.
var _hold_theta := 0.0

# Collision bits
const PLAYER_LAYER_BIT := 3
const FOSSIL_LAYER_BIT := 2
const WORLD_LAYER_BIT := 1

var weight = 0.0
var health = 100.0
@export var min_damage_speed := 4.0 # Threshold speed before collisions cause damage
@export var damage_per_speed := 1.0 # Damage multiplier per unit of impact speed

#contains a fieldLofInfo.initials and fieldLogInfo.description after the fieldLog has been attached to the fossilItem
var fieldLogInfo

func _ready() -> void:
	# Enable contact reporting so we can read contact data in _integrate_forces.
	# https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html#class-rigidbody3d-property-contact-monitor
	contact_monitor = true
	# https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html#class-rigidbody3d-property-max-contacts-reported
	max_contacts_reported = 8
	sleeping = false # ensure physics stays active so _integrate_forces runs
	fossil_res.weight = weight
	player = get_tree().root.get_node("Node3D/Player")

func interact():
	if player != null:
		reparent(player, true)
		gravity_scale = 0.0
		rotation = Vector3(0.0, 0.0, 0.0)
		isInteractable = false
		freeze = false
		sleeping = false
		# https://forum.godotengine.org/t/collisions-layers-masks/66193/2
		# Collision layer is what the body lies in. It's its little world, it just exists in that layer.
		collision_layer = (1 << (FOSSIL_LAYER_BIT - 1))
		# Collision mask is what the object looks towards when searching for collisions. It’s what it's interested in.
		collision_mask = 1 << (WORLD_LAYER_BIT - 1)
		set_collision_mask_value(PLAYER_LAYER_BIT, false) # ignore player while held

		# When picking up the fossil, we want to position it in front of the player at a certain hold distance and height, 
		# and we want it to rotate with the player's camera yaw. We do not want it to always be in front of the player's
		# camera, especially when they are looking up or down. So here's a simple solution: Let's have it always be
		# a certain distance from the player in the horizontal direction and a certain height relative to the player's origin
		# in the vertical direction. We will have its angle in the horizontal plane (theta) match the camera's yaw angle, 
		# so it will be in front of the player regardless of which direction they are looking, but it won't move up and down with the camera pitch. 
		# 
		# For a problem like this where we have two distances (hold distance and hold height) and an angle (theta),
		# cylindrical coordinates are a natural fit. The radius is the hold distance, the z (AKA h sometimes) is the hold height, 
		# and the angle theta is derived from the camera's forward vector projected onto the horizontal plane.
		# 
		# More about that forward vector: The camera's forward vector is the negative z basis vector of its global transform. 
		# We use the z basis vector because in Godot, the convention is that the forward direction of a camera or character is along the negative z axis.
		# Well what do the other basis vectors represent? The x basis vector represents the right direction, and the y basis vector represents the up direction.
		# Let's imagine a scenario where we have some camera at 0,0,0 in rectangular coordinates, oriented towards theta = 0, phi = 0 in spherical coordinates.
		# This translates to a global transform basis where the negative z axis points forward, the x axis points right, and the y axis points up.
		# If the camera then rotates to look up, let's say directly up so our phi = 90 degrees, the z basis vector would now point straight up, 
		# the x basis vector would still point to the right, and the y basis vector would now point backwards.
		# 
		# So since the camera's forward vector is the negative z basis vector, if we take the atan2 of the x and z components of that forward vector, 
		# we can get the camera's yaw angle (theta) in the horizontal plane.
		
		var cam: Node3D = player.get_node_or_null(camera_path)
		if cam:
			# cam_basis is a 3x3 matrix where the columns represent the camera's local x, y, and z axes in global space.
			# As stated before, we want the camera's forward vector, which is the negative z basis vector. 
			var cam_basis: Basis = cam.global_transform.basis

			# We normalize the forward vector to ensure it has a length of 1.
			# A basis vector need not be a normal vector. It is merely guaranteed to be a part of a minimal spanning set of vectors of the space.
			var forward: Vector3 = -cam_basis.z.normalized()

			# atan2 returns the angle in radians between the positive z axis and the point given by the x and z components of the forward vector,
			# which is effectively the camera's yaw angle in the horizontal plane. 
			_hold_theta = atan2(forward.x, forward.z)

			# We now get the player's global position for the sake of calculating the fossil's position relative to the player.
			var player_origin: Vector3 = player.global_transform.origin

			# The fossil's global position is then the player's global position plus an offset. 
			# The vertical component is easy, just add the hold height to the player's y coordinate. 
			# The horizontal component is also easy. 
			# Think of it like a circle. We want the fossil to be on the circumference of a circle around the player with radius equal to the hold distance.
			# The angle around that circle is the camera's yaw angle (theta), so we can use basic trigonometry to calculate the x and z offsets as 
			# sin(theta) * hold_distance and cos(theta) * hold_distance respectively. sin() for the x component and cos() for the z component (little weird since we usually think of cos for x and sin for y.)
			var offset := Vector3(sin(_hold_theta) * hold_distance, hold_height, cos(_hold_theta) * hold_distance)

			# Now we just add the offset.
			global_position = player_origin + offset
		else:

			# In case the camera is not found for some reason, 
			# we will fall back to a simple behavior of just parenting the fossil to the player and setting its position to the player's position,
			# which will at least ensure the fossil moves with the player even if it won't be held in front of them nicely.
			global_position = player.global_position
		player.is_holding = self
		
		var inv = player.get_node_or_null("Inventory")
		if inv and inv.has_method("add_item_to_inventory"):
			inv.add_item_to_inventory(fossil_res, 1)

func drop() -> bool:
	var cast = player.get_node("HeadPosition/LandingAnimation/Camera3D/SeeCast")
	var collider = cast.get_collider()
	if collider == null: #this check isn't perfect but it's better than nothing
		reparent(get_tree().root.get_node("Node3D/dc_terrain"), true)
		gravity_scale = 1.0
		isInteractable = true
		freeze = false
		sleeping = false
		collision_layer = (1 << (FOSSIL_LAYER_BIT - 1))
		collision_mask = (1 << (WORLD_LAYER_BIT - 1)) | (1 << (PLAYER_LAYER_BIT - 1)) # collide with world and player again
		position -= player.global_transform.basis.z * 1.25
		
		return player.remove_held_item()
	return false

## Called when the fossil's health reaches 0. Rewrite this function to extend behavior on destruction.
## Currently, it just prints a message and removes the fossil from the player's inventory if it's being held, 
## then removes the fossil from the scene.
func _on_health_depleted() -> void:
	print("Fossil destroyed! Health has reached zero.")
	
	# Remove from player's inventory if being held
	if player and player.is_holding == self:
		if player.has_method("remove_held_item"):
			player.remove_held_item()
	
	# Remove the fossil from the scene
	queue_free()

# https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html#class-rigidbody3d-private-method-integrate-forces
# This function is called during the physics step and allows us to read contact data to implement custom collision responses, 
# in this case applying damage based on impact speed.

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# See the above comments in interact() for the rationale behind this code. 
	if player and player.is_holding == self:
		# If we have a player and the player is holding this fossil, 
		# let's position the fossil in front of the player at the specified hold distance and height, and rotate it with the player's camera yaw.
		var cam: Node3D = player.get_node_or_null(camera_path)
		var cam_basis: Basis = cam.global_transform.basis if cam else player.global_transform.basis
		var forward: Vector3 = -cam_basis.z.normalized()
		_hold_theta = atan2(forward.x, forward.z)
		# print("Camera theta (deg)=", rad_to_deg(_hold_theta))
		var origin: Vector3 = player.global_transform.origin
		var offset := Vector3(sin(_hold_theta) * hold_distance, hold_height, cos(_hold_theta) * hold_distance)
		var target: Vector3 = origin + offset
		# In interact(), we were done after setting the global position.
		# But here, we need to do something more involved. When we do global_position = player_origin + offset in interact(),
		# we're immediately moving the fossil to the target position, which is fine for the initial placement when we pick it up. 
		# But if we did that every physics frame in _integrate_forces, we would be essentially teleporting the fossil to the target 
		# position every frame, which could break the physics simulation.
		# Instead, we want to apply a force that moves the fossil towards the target position in a more natural way that still allows for physics interactions.

		# xf is the transform of the body in the physics simulation. 
		# That is, the physics engine is simulating the movement of the fossil based on forces and collisions, 
		# and xf is the current position and orientation of the fossil in that simulation.
		var xf := state.transform

		# By setting the origin of the transform to the target position, 
		# we are effectively telling the physics engine that the position we want the fossil to be at is the target position in front of the player.
		xf.origin = target

		# Now for the rotation. We want the fossil to rotate with the player's camera yaw, which is represented by _hold_theta.
		# This is so that if for example the player is holding the fossil and looking around, if they look to the north, 
		# they will see the front of the fossil, and if they look to the south, they will still see the front of the fossil, 
		# instead of the fossil always being oriented in the same direction regardless of where the player is looking.

		# To achieve this, we can construct a new basis for the transform that has the desired yaw angle.
		# We can create a basis from Euler angles, where we set the yaw (rotation around the vertical axis) 
		# to _hold_theta, and leave pitch and roll as 0.
		# https://docs.godotengine.org/en/stable/classes/class_basis.html
		# https://en.wikipedia.org/wiki/Euler_angles
		# Euler angles are the three angles that represent rotations around the three principal axes (usually x, y, z).
		# In Godot, the convention is that yaw is rotation around the y axis, pitch is rotation around the x axis, and roll is rotation around the z axis.
		# So by creating a basis with Euler angles of (0, _hold_theta, 0), we are creating a rotation that only has yaw and no pitch or roll, 
		# which has the effect of rotating the fossil to match the camera's yaw while ignoring the camera's pitch and roll.
		var yaw_basis: Basis = Basis(Vector3.UP, cam_basis.get_euler().y)

		# We orthonormalize the basis to ensure it is a valid rotation matrix. All rotation matrices should be orthonormal, 
		# meaning each column is a unit vector and the columns are mutually orthogonal (defined in various ways but one simple one 
		# is that the dot product of any two different columns should be zero).
		yaw_basis.orthonormalized()

		# By setting the basis of the transform to our new yaw_basis, 
		# the physics engine will now understand that the orientation we want for the fossil is the one defined by yaw_basis, 
		# which has the correct yaw angle to match the player's camera.
		xf.basis = yaw_basis

		# Now that we have set the desired position and orientation in the transform, we assign it back to the physics state.
		state.transform = xf

		# When the fossil is being held, it should not be able to move independently due to physics forces, because we want it to stay in front of the player.
		# So we set its linear and angular velocity to zero to prevent it from drifting or rotating due to physics while it's being held.
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO

	# https://docs.godotengine.org/en/stable/classes/class_physicsdirectbodystate3d.html#class-physicsdirectbodystate3d-method-get-contact-count
	# Returns the number of contacts (collisions) currently involving this body. 
	var contact_count := state.get_contact_count()
	if contact_count == 0:
		# No contacts, so nothing to process for damage.
		return

	# Approximate linear velocity even when the body is driven kinematically by parenting.
	var carrier_vel := Vector3.ZERO
	var using_carrier := false
	if player and player.is_holding == self and player.has_method("get_real_velocity"):
		carrier_vel = player.get_real_velocity()
		using_carrier = true

	print("Carrier velocity: ", carrier_vel, ", carrier speed: ", carrier_vel.length())
	# Keeps track of which contact had the highest relative speed, so we can apply damage based on that.
	# We don't sum damage across contacts because that leads to a lot more damage than might be expected by the player,
	# who from their perspective might have just hit one thing, not multiple things at once. 
	var max_speed := 0.0
	for i in contact_count:
		# https://docs.godotengine.org/en/stable/classes/class_physicsdirectbodystate3d.html#class-physicsdirectbodystate3d-method-get-contact-local-velocity-at-position
		# Returns the relative velocity at the contact point in local space. 
		# This is the velocity of the other body relative to this one.
		var rel_vel := state.get_contact_local_velocity_at_position(i)
		var contact_normal := state.get_contact_local_normal(i)
		var normal_speed : float
		if using_carrier:
			normal_speed = abs(carrier_vel.dot(contact_normal))
		else:
			normal_speed = abs(rel_vel.dot(contact_normal))
		max_speed = max(max_speed, rel_vel.length(), normal_speed)

	# print("Max impact speed from contacts: ", max_speed)

	# We only apply damage if the impact speed exceeds our threshold, 
	# so stuff like just leaving the fossil on the ground or gently placing it down doesn't cause damage.
	if max_speed >= min_damage_speed:
		print("Applying damage from impact. Impact speed: ", max_speed, ", Health before: ", health)
		# We calculate damage as a linear function of how much the impact speed exceeds the threshold, multiplied by our damage multiplier.
		# This is opposed to calculating it as max_speed * damage_per_speed, as that would mean anything barely above the threshold could cause a lot of damage
		# if the threshold is high enough, while something barely below the threshold would cause no damage at all, which could be frustrating.
		health -= (max_speed - min_damage_speed) * damage_per_speed
		
		# Check if fossil has been destroyed
		if health <= 0:
			_on_health_depleted()
