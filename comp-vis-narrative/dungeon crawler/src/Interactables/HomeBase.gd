extends Area3D

@export var victory_label: Label  # assign in Inspector

@onready var ringEffect = $RingEffect

#@onready var homeBase = $HomeBase
var player

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	moveRing()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	if player.is_holding == null:
		hide()
	else:
		show()
	
func _on_body_entered(body):
	print("intersection :)")
	if body.is_in_group("player") && body.is_holding != null:
		#get the current time to store
		var time = Time.get_time_dict_from_system()
		var hour = time.hour
		var minute = time.minute
		var period = "am"
		if hour >= 12:
			period = "pm"
		hour = hour % 12
		if hour == 0:
			hour = 12
		
		#store fossil info for journal
		DungeonCrawlerData.collectedLogs.append(
			{ "initials": body.is_holding.fieldLogInfo.initials,
			"description": body.is_holding.fieldLogInfo.description,
			"time": "%d:%02d%s" % [hour, minute, period],
			"fossil_path": body.is_holding.fossilScenePath
			})
			
		player.levelUpManager_instance.giveXp(body.is_holding.weight)
			
		print("Fossil's log attached to global data")
		if (body.remove_held_item()):
			body.is_holding.queue_free()
			body.is_holding = null
			show_victory_message()
			print(DungeonCrawlerData.collectedLogs)

func show_victory_message():
	print("victory message")
	if victory_label:
		victory_label.text = "🦕 Fossil secured! Great find, paleontologist!"
		victory_label.visible = true
		# Hide it after 3 seconds
		await get_tree().create_timer(3.0).timeout
		victory_label.visible = false

func moveRing():
	var tween = create_tween()
	tween.set_loops()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(ringEffect, "position", Vector3(0, 0.5, 0), 1.0)
	tween.tween_property(ringEffect, "position", Vector3(0, 0, 0), 1.0)
		
