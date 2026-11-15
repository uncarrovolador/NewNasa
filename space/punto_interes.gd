
extends Area2D

@export var tipo_interaccion: String = "fotografia"

var rover_cerca: bool = false

@onready var mensaje = $Label



func _ready() -> void:
	mensaje.hide()

	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)


func _al_entrar(body: Node2D) -> void:
	if body is CharacterBody2D:
		rover_cerca = true
		mensaje.show()


func _al_salir(body: Node2D) -> void:
	if body is CharacterBody2D:
		rover_cerca = false
		mensaje.hide()


func _process(_delta: float) -> void:
	if rover_cerca and Input.is_action_just_pressed("interactuar"):
		ejecutar_interaccion()


func ejecutar_interaccion() -> void:

	match tipo_interaccion:

		"fotografia":
			print("Fotografía capturada")

		"excavacion":
			print("Iniciando excavación")

		"escaneo":
			print("Analizando superficie")

		"exploracion":
			print("Zona de exploración registrada")

		"deteccion_hidrogeno":
			print("Analizando posibles indicios de hidrógeno")

		"llegar_perforacion":
			print("Punto de perforación alcanzado")

		"analisis":
			print("Análisis de muestra completado")

		_:
			print("Interacción no reconocida")

	Misionextra.registrar_interaccion(tipo_interaccion)
