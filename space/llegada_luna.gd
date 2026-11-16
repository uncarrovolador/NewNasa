extends Control

func _on_regreso_pressed() -> void:
	get_tree().change_scene_to_file("res://mision2.tscn")
	
func _on_mission_1_pressed() -> void:
	Misionextra.seleccionar_mision(1)
	print("Misión seleccionada: ", Misionextra.mision)
	get_tree().change_scene_to_file("res://mision2.tscn")


func _on_mission_2_pressed() -> void:
	Misionextra.seleccionar_mision(2)
	print("Misión seleccionada: ", Misionextra.mision)
	get_tree().change_scene_to_file("res://mision2.tscn")


func _on_mission_3_pressed() -> void:
	Misionextra.seleccionar_mision(3)
	print("Misión seleccionada: ", Misionextra.mision)
	get_tree().change_scene_to_file("res://mision2.tscn")
