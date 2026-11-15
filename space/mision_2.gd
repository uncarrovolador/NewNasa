extends Control

const ROCKET_CUSTOMIZER_SCENE = preload("res://space_customizer/scenes/CustomizerBase.tscn")
var active_customizer: Control = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_orbitas_pressed() -> void:
	get_tree().change_scene_to_file("res://entradaorbita.tscn")

	pass # Replace with function body.


func _on_rover_pressed() -> void:
	get_tree().change_scene_to_file("res://rover.tscn")
	pass # Replace with function body.


func _on_llegadaalaluna_pressed() -> void:
	get_tree().change_scene_to_file("res://llegada_luna.tscn")
	pass # Replace with function body.


func _on_launch_pressed() -> void:
	get_tree().change_scene_to_file("res://video_despeje.tscn")
	pass # Replace with function body.

func _on_nave_2_pressed() -> void:
	# Evita abrirlo dos veces si se hace doble clic
	if is_instance_valid(active_customizer):
		return
	
	active_customizer = ROCKET_CUSTOMIZER_SCENE.instantiate()
	
	# Lo muestra en una capa superior para cubrir toda la pantalla
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	ui_layer.add_child(active_customizer)
	
	# Al presionar el botón de cerrar (X), borra la capa temporal
	active_customizer.customizer_closed.connect(func():
		ui_layer.queue_free()
		active_customizer = null
	)
