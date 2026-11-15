extends CanvasLayer

@onready var barra: ProgressBar = $PanelEstadoRover/ContenidoEstado/BarraIntegridad
@onready var rover = get_parent().get_node("roversito/rover")

@onready var panel_derrota = $PanelDerrota
@onready var boton_reintentar = $PanelDerrota/Contenido/BotonReintentar

@onready var nombre_mision: Label = $PanelObjetivos/ContenidoObjetivos/NombreMision
@onready var objetivo_1: Label = $PanelObjetivos/ContenidoObjetivos/Objetivo1
@onready var objetivo_2: Label = $PanelObjetivos/ContenidoObjetivos/Objetivo2
@onready var objetivo_3: Label = $PanelObjetivos/ContenidoObjetivos/Objetivo3

@onready var contenido_objetivos = $PanelObjetivos/ContenidoObjetivos
@onready var contenido_estado = $PanelEstadoRover/ContenidoEstado

@onready var boton_objetivos = $PanelObjetivos/ContenidoObjetivos/BotonContraerObjetivos
@onready var boton_estado = $PanelEstadoRover/ContenidoEstado/BotonContraerEstado

@onready var panel_victoria = $PanelVictoria

var objetivos_expandidos: bool = true
var estado_expandido: bool = true

func _ready() -> void:
	barra.min_value = 0
	barra.max_value = 100
	barra.value = rover.obtener_integridad()

	panel_derrota.hide()
	panel_victoria.hide()

	rover.mision_fallida.connect(_al_finalizar_mision)
	boton_reintentar.pressed.connect(_reiniciar_mision)

	actualizar_objetivos()
	
	Misionextra.progreso_actualizado.connect(actualizar_hud_objetivos)
	Misionextra.mision_completada.connect(_al_completar_mision)
	actualizar_hud_objetivos()
	
	boton_objetivos.pressed.connect(_alternar_objetivos)
	boton_estado.pressed.connect(_alternar_estado)

func _process(_delta: float) -> void:
	var integridad = rover.obtener_integridad()
	barra.value = integridad


func _al_finalizar_mision() -> void:
	panel_derrota.show()


func _reiniciar_mision() -> void:
	get_tree().reload_current_scene()
	
func actualizar_objetivos() -> void:

	match Misionextra.mision:

		1:
			nombre_mision.text = "Reconocimiento de Mares Lunares"

			objetivo_1.text = "○ Explorar la zona asignada"
			objetivo_2.text = "○ Capturar imágenes panorámicas"
			objetivo_3.text = "○ Registrar características del terreno"

		2:
			nombre_mision.text = "Búsqueda de Hielo en el Polo Sur"

			objetivo_1.text = "○ Explorar cráteres de sombra"
			objetivo_2.text = "○ Realizar escaneos de superficie"
			objetivo_3.text = "○ Registrar posibles indicios de hidrógeno"

		3:
			nombre_mision.text = "Perforación y Espectrometría Profunda"

			objetivo_1.text = "○ Llegar al punto de perforación"
			objetivo_2.text = "○ Recolectar una muestra de regolito"
			objetivo_3.text = "○ Registrar el análisis espectrométrico"

		_:
			nombre_mision.text = "Misión no seleccionada"

			objetivo_1.text = "Selecciona una misión"
			objetivo_2.text = ""
			objetivo_3.text = ""
		
func actualizar_hud_objetivos() -> void:

	var objetivos: Array = []

	match Misionextra.mision:

		1:
			objetivos = [
				"Explorar la zona asignada",
				"Capturar imágenes panorámicas",
                "Registrar características del terreno"
			]

		2:
			objetivos = [
				"Explorar cráteres de sombra",
				"Realizar escaneos de superficie",
                "Registrar posibles indicios de hidrógeno"
			]

		3:
			objetivos = [
				"Llegar al punto de perforación",
				"Recolectar una muestra de regolito",
                "Registrar el análisis espectrométrico"
			]

		_:
			nombre_mision.text = "Misión no seleccionada"
			return

	var etiquetas: Array[Label] = [
		objetivo_1,
		objetivo_2,
		objetivo_3
	]

	for i in range(3):

		if Misionextra.objetivos_completados[i]:
			etiquetas[i].text = "✓ " + objetivos[i]
		else:
			etiquetas[i].text = "○ " + objetivos[i]


func _al_completar_mision() -> void:
	panel_victoria.show()
	print("¡MISIÓN COMPLETADA!")
	
func _alternar_objetivos() -> void:

	objetivos_expandidos = not objetivos_expandidos

	for hijo in contenido_objetivos.get_children():
		if hijo != boton_objetivos:
			hijo.visible = objetivos_expandidos

	if objetivos_expandidos:
		boton_objetivos.text = "▼ OBJETIVOS DE MISIÓN"
	else:
		boton_objetivos.text = "▶ OBJETIVOS DE MISIÓN"


func _alternar_estado() -> void:

	estado_expandido = not estado_expandido

	for hijo in contenido_estado.get_children():
		if hijo != boton_estado:
			hijo.visible = estado_expandido

	if estado_expandido:
		boton_estado.text = "▼ ESTADO DEL ROVER"
	else:
		boton_estado.text = "▶ ESTADO DEL ROVER"
