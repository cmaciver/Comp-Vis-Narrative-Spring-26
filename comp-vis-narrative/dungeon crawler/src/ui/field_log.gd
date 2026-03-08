extends Control

signal log_screen_closed(initials, description)

var finishedInitials
var finishedDescription

#needed to tell if the log can be edited (important for the journal)
var is_interactive = false

func _ready() -> void:
	#hiding the continue text for the sake of the logbook
	%ContinueInfo.hide()
	%Date.text = str(Time.get_date_dict_from_system()["day"]) + " - " + str(Time.get_date_dict_from_system()["month"]) + " - " + str(Time.get_date_dict_from_system()["year"])

func preparePopup():
	is_interactive = true
	#move offscreen for the shifting function
	position = Vector2(0, get_viewport_rect().size.y)
	moveIntoScreen()
	
	#fade the continue text in after 4 seconds
	%ContinueInfo.modulate.a = 0.0
	fadeInContinueText()

func updateWithFossilInfo(intials, description):
	%Initials.text = intials
	%Description.text = description
	
func updateDescription(description):
	%Description.text = description

#so that the player can not edit the log in their journal
func disableEdits():
	is_interactive = false
	%Initials.editable = false

func moveIntoScreen():
	var tween = create_tween()
	tween.set_ease(tween.EASE_OUT)
	tween.set_trans(tween.TRANS_QUINT)
	tween.tween_property(self, "position", Vector2(0, 0), 2.0)

func moveOffScreen():
	var tween = create_tween()
	tween.set_ease(tween.EASE_IN)
	tween.set_trans(tween.TRANS_QUINT)
	tween.tween_property(self, "position", Vector2(0, get_viewport_rect().size.y), 1.0)
	tween.tween_callback(queue_free)
	

func fadeInContinueText():
	%ContinueInfo.show()
	var tween = create_tween()
	
	#wait 4 seconds
	tween.tween_interval(4.0)
	
	#fade in over 1 seconds
	tween.tween_property(%ContinueInfo, "modulate:a", 1.0, 1.0)

#detect the enter key being pressed and then close this menu after sending a signal
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER and is_interactive == true:
		finishedInitials = %Initials.text
		finishedDescription = %Description.text
		emit_signal("log_screen_closed", finishedInitials, finishedDescription)
		moveOffScreen()
