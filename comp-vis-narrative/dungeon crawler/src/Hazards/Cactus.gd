extends StaticBody3D

# the amount of time between hits
@export var damage_interval: float = 0.5

var player_inside: bool = false
var timer: float = 0.0

func _ready() -> void:
	print("Cactus ready, Area3D: ", $Area3D)
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)
	print("Signal connected")

func _physics_process(delta: float) -> void:
	if player_inside:
		timer += delta
		if timer >= damage_interval:
			timer = 0.0
			_damage_player()

func _on_body_entered(body: Node3D) -> void:
	print("Something entered: ", body.name)
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
