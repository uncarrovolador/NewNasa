extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("Clic en: ", event.position, " | Nodo bajo el mouse: ", get_viewport().gui_get_hovered_control())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_mision_1_boton_pressed() -> void:
	get_tree().change_scene_to_file("res://mision_1.tscn")
	pass # Replace with function body.


func _on_mision_2_boton_pressed() -> void:
	get_tree().change_scene_to_file("res://mision2.tscn")
	pass # Replace with function body.


func _on_misin_3_boton_pressed() -> void:
	get_tree().change_scene_to_file("res://mision_3.tscn")
	pass # Replace with function body.
