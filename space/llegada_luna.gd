extends Control

func _on_regreso_pressed() -> void:
	get_tree().change_scene_to_file("res://mision2.tscn")

func _on_mission_1_pressed() -> void:
	MissionState.set_mission("MIS_A")
	get_tree().change_scene_to_file("res://mision2.tscn")

func _on_mission_2_pressed() -> void:
	MissionState.set_mission("MIS_B")
	get_tree().change_scene_to_file("res://mision2.tscn")

func _on_mission_3_pressed() -> void:
	MissionState.set_mission("MIS_C")
	get_tree().change_scene_to_file("res://mision2.tscn")
