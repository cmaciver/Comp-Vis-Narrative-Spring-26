extends StaticBody3D

# the amount of time between hits
@export var damage_interval: float = 1.5

var player_inside: bool = false
var timer: float = 0.0

func _ready() -> void:
	#print("Cactus ready, Area3D: ", $Area3D)
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)
	#print("Signal connected")

func _physics_process(delta: float) -> void:
	if player_inside:
		timer += delta
		if timer >= damage_interval:
			timer = 0.0
			_damage_player()
			_drop_item()

func _on_body_entered(body: Node3D) -> void:
	#print("Something entered: ", body.name)
	if body == self:
		return
	var player = get_tree().get_first_node_in_group("player")
	if body == player:
		player_inside = true
		timer = damage_interval # damage immediately on first contact

func _on_body_exited(body: Node3D) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if body == player:
		player_inside = false
		timer = 0.0

func _drop_item() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	if player.is_holding and player.is_holding.has_method("_force_release_hold"):
		player.is_holding._force_release_hold()

func _damage_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.stamina = 0.0
		player.can_sprint = false
		player._update_stamina_bar()
		print("Cactus hit! Stamina after: ", player.stamina)
		if player.hud:
			var flash = player.hud.get_node_or_null("Control/DamageFlash")
			if flash:
				flash.flash()

	# Try to locate the audio manager by node name in the active scene tree.
	var audio_manager = get_tree().root.get_node("Node3D/DungeonCrawlerAudioManager")
	if audio_manager and audio_manager.has_method("play_sound_effect"):
		# We want playerPain5 to have a 1% chance of playing while the other 4 pain sounds have an equal share of the remaining 99% chance.
		var rand_num = randi_range(1, 100)
		var sound_key = ""
		if rand_num <= 1:
			sound_key = "playerPain5"
		else:
			sound_key = "playerPain" + str(randi_range(1, 4))
		audio_manager.play_sound_effect(sound_key)
