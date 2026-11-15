extends Node

signal progreso_actualizado
signal mision_completada

var mision: int = 0

var objetivos_completados: Array = [false, false, false]
var mision_terminada: bool = false


# Seleccionar una misión y reiniciar su progreso
func seleccionar_mision(numero: int) -> void:
	mision = numero
	objetivos_completados = [false, false, false]
	mision_terminada = false
	progreso_actualizado.emit()


# Registrar la finalización de un objetivo
func registrar_objetivo(indice: int) -> void:

	if mision == 0 or mision_terminada:
		return

	if indice < 0 or indice >= objetivos_completados.size():
		return

	if objetivos_completados[indice]:
		return

	objetivos_completados[indice] = true

	print("Objetivo ", indice + 1, " completado")

	progreso_actualizado.emit()

	# Comprobar si todos los objetivos están completos
	if objetivos_completados.all(func(completado): return completado):
		mision_terminada = true
		print("¡MISIÓN COMPLETADA!")
		mision_completada.emit()


# Registrar una interacción según la misión seleccionada
func registrar_interaccion(tipo: String) -> void:

	match mision:

		1:
			match tipo:
				"exploracion":
					registrar_objetivo(0)
				"fotografia":
					registrar_objetivo(1)
				"escaneo":
					registrar_objetivo(2)

		2:
			match tipo:
				"exploracion":
					registrar_objetivo(0)
				"escaneo":
					registrar_objetivo(1)
				"deteccion_hidrogeno":
					registrar_objetivo(2)

		3:
			match tipo:
				"llegar_perforacion":
					registrar_objetivo(0)
				"excavacion":
					registrar_objetivo(1)
				"analisis":
					registrar_objetivo(2)
