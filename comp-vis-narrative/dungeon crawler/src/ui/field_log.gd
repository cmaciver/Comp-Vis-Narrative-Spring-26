extends Control

func _ready() -> void:
	%Date.text = str(Time.get_date_dict_from_system()["day"]) + " - " + str(Time.get_date_dict_from_system()["month"]) + " - " + str(Time.get_date_dict_from_system()["year"])
