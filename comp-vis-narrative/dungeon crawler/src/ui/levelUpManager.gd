extends Control

@onready var xpFillBubble = $XPBar/XPBarFill
@onready var weightLabel = $WeightToXPContainer/weightLabel
@onready var xpLabel = $WeightToXPContainer/xpLabel
@onready var xpBarContainer = $XPBar
@onready var weightToXpContainer = $WeightToXPContainer
@onready var promotionLabel = $PromotionGroup
@onready var positionText = $PromotionGroup/Control/VBoxContainer/PositionText
@onready var journalTip = $JournalTip

var rankTitles = ["Intern", "Associate", "Full-Time", "Senior", "Lead", "Principal"]

var currRankIndex: int = 0

var currXp: int = 0
var remainingXp: int = 0
var totalWeight: int = 0

func giveXp(xp: int):
	var startXp = currXp
	var startWeight = xp
	totalWeight = xp
	
	#give the text boxes the correct starting text
	weightLabel.text = str(currXp) + " / " + str(totalWeight) + " lbs"
	xpLabel.text = str(0) + " xp"
	
	if xpFillBubble.size == Vector2(1000, 50):
		xpFillBubble.size = Vector2(60, 50)
	
	weightToXpContainer.show()
	weightToXpContainer.modulate.a = 0.0
	xpBarContainer.show()
	xpBarContainer.modulate.a = 0.0
	
	var fadeTween = create_tween()
	fadeTween.set_parallel(true)
	fadeTween.tween_property(weightToXpContainer, "modulate:a", 1.0, 1.0)
	fadeTween.tween_property(xpBarContainer, "modulate:a", 1.0, 1.0)
	await fadeTween.finished
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(tween.TRANS_QUART)
	tween.set_parallel(true)
	
	if currXp + xp >= 100:
		#xp left after we reach 100
		remainingXp = startXp + xp - 100
		var weightOutOfHundred = 100 - startXp
		var targetWidth = 1000
		tween.tween_property(xpFillBubble, "size:x", targetWidth, 3)
		tween.tween_method(set_weight_label, 0, float(weightOutOfHundred), 3)
		tween.tween_method(set_xp_label, float(startXp), 100.0, 3)
		await tween.finished
		currXp = 0
		level_up(remainingXp)
	else:
		currXp = currXp + xp
		var targetWidth = 60 + (currXp / 100.0) * (1000 - 60)
		tween.tween_property(xpFillBubble, "size:x", targetWidth, 3)
		tween.tween_method(set_weight_label, 0.0, float(xp), 3)
		tween.tween_method(set_xp_label, float(startXp), currXp, 3)
		
		#fade out
		tween.set_parallel(false)
		tween.tween_interval(4.0)
		tween.set_parallel(true)
		tween.tween_property(weightToXpContainer, "modulate:a", 0.0, 1)
		tween.tween_property(xpBarContainer, "modulate:a", 0.0, 1)
		
		tween.set_parallel(false)
		#tween.tween_interval(1.0)
		journalTip.show()
		journalTip.modulate.a = 0.0
		tween.tween_property(journalTip, "modulate:a", 1.0, 1)
		tween.tween_property(journalTip, "modulate:a", 0.0, 1).set_delay(2.0)

func level_up(xp: int):
	start_rainbow()
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(tween.TRANS_QUART)
	tween.set_parallel(true)
	#do other levelup stuff HERE
	tween.tween_property(weightToXpContainer, "modulate:a", 0.0, 3)
	
	tween.tween_property(xpBarContainer, "modulate:a", 0.0, 3)
	
	await tween.finished
	
	await swipeInPromotionGroup()
	
	if remainingXp > 0:
		giveXp(remainingXp)
	

#swipes the promotion label across the screen
func swipeInPromotionGroup():
	var screen_width = get_viewport_rect().size.x
	var center_x = screen_width / 2.0 - promotionLabel.size.x / 2.0
	
	promotionLabel.position.x = -promotionLabel.size.x
	if currRankIndex < rankTitles.size():
		positionText.text = "[b]" + rankTitles[currRankIndex] + "[/b]"
	else:
		positionText.text = "[b]" + rankTitles[rankTitles.size() - 1] + "[/b]"
	currRankIndex = currRankIndex + 1
	promotionLabel.show()
	
	var tween = create_tween()
	tween.tween_property(promotionLabel, "position:x", center_x, 1)\
	.set_ease(Tween.EASE_OUT)\
	.set_trans(Tween.TRANS_QUART)
	
	tween.tween_interval(1.5)
	
	tween.tween_property(promotionLabel, "position:x", screen_width + promotionLabel.size.x, 1)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_QUART)
	
	tween.tween_callback(promotionLabel.hide)
	await tween.finished

func set_weight_label(value: float):
	weightLabel.text = str(roundi(value)) + " / " + str(totalWeight) + " lbs"

func set_xp_label(value: float):
	xpLabel.text = str(roundi(value)) + " xp"

#Activates the rainbow shader (I have literally no idea how this shader works but it does)
func start_rainbow():
	var mat = xpFillBubble.material
	mat.set_shader_parameter("bar_width", xpFillBubble.size.x)

	var tween = create_tween()
	tween.tween_method(set_rainbow_active, 0.0, 1.0, 1.0)  # fade in
	tween.tween_interval(3.0)   
	tween.tween_callback(func(): set_rainbow_active(0.0))
	
func set_rainbow_active(value: float):
	xpFillBubble.material.set_shader_parameter("active", value)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hideElements()

func hideElements():
	weightToXpContainer.hide()
	xpBarContainer.hide()
	promotionLabel.hide()
	journalTip.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
