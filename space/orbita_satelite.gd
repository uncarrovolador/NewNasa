
extends Control

# ==========================================
# SIMULADOR DE LANZAMIENTO DE SATELITE
# ==========================================

# Variables de simulacion (unidades visuales)

var altura_orbital: float = 180.0
var velocidad_simulacion: float = 1.0

var tiempo: float = 0.0

var lanzado: bool = false
var pausado: bool = false
var satelite_liberado: bool = false

var estado: String = "LISTO PARA EL LANZAMIENTO"

# Etapas de la mision

const TIEMPO_DESPEGUE = 3.0
const TIEMPO_ASCENSO = 7.0
const TIEMPO_SEPARACION = 2.0

# Datos visuales

var tierra: Vector2
var posicion_cohete: Vector2
var posicion_satelite: Vector2

var angulo_orbital: float = -PI / 2.0

var trayectoria: PackedVector2Array = []

# Interfaz

var etiqueta_estado: Label
var etiqueta_tiempo: Label
var etiqueta_altura: Label
var etiqueta_etapa: Label

var boton_lanzar: Button
var boton_pausa: Button


# ==========================================
# INICIO
# ==========================================

func _ready() -> void:

	crear_interfaz()
	actualizar_escenario()

	queue_redraw()


func _process(delta: float) -> void:

	if lanzado and not pausado:

		tiempo += delta * velocidad_simulacion

		actualizar_escenario()
		actualizar_interfaz()

		queue_redraw()


# ==========================================
# CENTRO DE LA TIERRA
# ==========================================

func obtener_tierra() -> Vector2:

	var pantalla = get_viewport_rect().size

	return Vector2(
		pantalla.x * 0.64,
		pantalla.y * 0.57
	)


# ==========================================
# ACTUALIZAR MISION
# ==========================================

func actualizar_escenario() -> void:

	tierra = obtener_tierra()

	var radio_tierra = 78.0

	# ETAPA 1: DESPEGUE

	if tiempo < TIEMPO_DESPEGUE:

		var t = tiempo / TIEMPO_DESPEGUE

		var altura = lerp(
			radio_tierra,
			radio_tierra + 65.0,
			smoothstep(0.0, 1.0, t)
		)

		posicion_cohete = tierra + Vector2(0, -altura)

		posicion_satelite = posicion_cohete

		estado = "DESPEGANDO"

	# ETAPA 2: ASCENSO

	elif tiempo < TIEMPO_DESPEGUE + TIEMPO_ASCENSO:

		var t = (
			tiempo - TIEMPO_DESPEGUE
		) / TIEMPO_ASCENSO

		var altura = lerp(
			radio_tierra + 65.0,
			altura_orbital,
			smoothstep(0.0, 1.0, t)
		)

		posicion_cohete = tierra + Vector2(0, -altura)

		posicion_satelite = posicion_cohete

		estado = "ASCENSO ORBITAL"

	# ETAPA 3: SEPARACION

	elif tiempo < TIEMPO_DESPEGUE + TIEMPO_ASCENSO + TIEMPO_SEPARACION:

		var t = (
			tiempo - TIEMPO_DESPEGUE - TIEMPO_ASCENSO
		) / TIEMPO_SEPARACION

		var angulo = lerp(-PI / 2.0, -PI / 2.0 + 0.12, t)

		posicion_satelite = tierra + Vector2(
			cos(angulo) * altura_orbital,
			sin(angulo) * altura_orbital
		)

		posicion_cohete = posicion_satelite

		estado = "LIBERANDO SATELITE"

	# ETAPA 4: ORBITA

	else:

		satelite_liberado = true

		var tiempo_orbita = (
			tiempo -
			TIEMPO_DESPEGUE -
			TIEMPO_ASCENSO -
			TIEMPO_SEPARACION
		)

		angulo_orbital = -PI / 2.0 + tiempo_orbita * 0.55

		posicion_satelite = tierra + Vector2(
			cos(angulo_orbital) * altura_orbital,
			sin(angulo_orbital) * altura_orbital
		)

		estado = "SATELITE EN ORBITA TERRESTRE"

	# Guardar trayectoria del satelite

	if satelite_liberado:

		if trayectoria.is_empty() or posicion_satelite.distance_to(
			trayectoria[trayectoria.size() - 1]
		) > 1.5:

			trayectoria.append(posicion_satelite)

		if trayectoria.size() > 1200:
			trayectoria.remove_at(0)


# ==========================================
# LANZAR
# ==========================================

func lanzar() -> void:

	tiempo = 0.0

	trayectoria.clear()

	lanzado = true
	pausado = false
	satelite_liberado = false

	boton_lanzar.disabled = true
	boton_pausa.disabled = false

	boton_pausa.text = "PAUSAR"

	actualizar_escenario()
	actualizar_interfaz()

	queue_redraw()


# ==========================================
# PAUSAR
# ==========================================

func cambiar_pausa() -> void:

	if not lanzado:
		return

	pausado = not pausado

	if pausado:

		boton_pausa.text = "REANUDAR"

	else:

		boton_pausa.text = "PAUSAR"

	actualizar_interfaz()


# ==========================================
# REINICIAR
# ==========================================

func reiniciar() -> void:

	tiempo = 0.0

	lanzado = false
	pausado = false
	satelite_liberado = false

	trayectoria.clear()

	estado = "LISTO PARA EL LANZAMIENTO"

	boton_lanzar.disabled = false
	boton_pausa.disabled = true

	boton_pausa.text = "PAUSAR"

	actualizar_escenario()
	actualizar_interfaz()

	queue_redraw()


# ==========================================
# CREAR INTERFAZ
# ==========================================

func crear_interfaz() -> void:

	var panel = PanelContainer.new()

	panel.position = Vector2(20, 20)
	panel.custom_minimum_size = Vector2(300, 0)

	add_child(panel)

	var columna = VBoxContainer.new()

	columna.add_theme_constant_override(
		"separation", 10
	)

	panel.add_child(columna)

	# Titulo

	var titulo = Label.new()

	titulo.text = "SATELLITE LAUNCH SYSTEM"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	columna.add_child(titulo)

	columna.add_child(HSeparator.new())

	# Estado

	etiqueta_estado = Label.new()
	columna.add_child(etiqueta_estado)

	etiqueta_etapa = Label.new()
	columna.add_child(etiqueta_etapa)

	etiqueta_tiempo = Label.new()
	columna.add_child(etiqueta_tiempo)

	etiqueta_altura = Label.new()
	columna.add_child(etiqueta_altura)

	columna.add_child(HSeparator.new())

	# Altura orbital

	var titulo_altura = Label.new()

	titulo_altura.text = "ALTURA ORBITAL (visual)"

	columna.add_child(titulo_altura)

	var slider_altura = HSlider.new()

	slider_altura.min_value = 130.0
	slider_altura.max_value = 240.0
	slider_altura.step = 5.0
	slider_altura.value = altura_orbital

	slider_altura.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	columna.add_child(slider_altura)

	slider_altura.value_changed.connect(
		func(valor):
			if not lanzado:
				altura_orbital = valor
				actualizar_interfaz()
				queue_redraw()
	)

	columna.add_child(HSeparator.new())

	# Velocidad

	var titulo_velocidad = Label.new()

	titulo_velocidad.text = "VELOCIDAD DE SIMULACION"

	columna.add_child(titulo_velocidad)

	var slider_velocidad = HSlider.new()

	slider_velocidad.min_value = 0.2
	slider_velocidad.max_value = 3.0
	slider_velocidad.step = 0.1
	slider_velocidad.value = velocidad_simulacion

	slider_velocidad.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	columna.add_child(slider_velocidad)

	slider_velocidad.value_changed.connect(
		func(valor):
			velocidad_simulacion = valor
			actualizar_interfaz()
	)

	columna.add_child(HSeparator.new())

	# Lanzar

	boton_lanzar = Button.new()

	boton_lanzar.text = "LANZAR COHETE"

	columna.add_child(boton_lanzar)

	boton_lanzar.pressed.connect(lanzar)

	# Pausar

	boton_pausa = Button.new()

	boton_pausa.text = "PAUSAR"
	boton_pausa.disabled = true

	columna.add_child(boton_pausa)

	boton_pausa.pressed.connect(cambiar_pausa)

	# Reiniciar

	var boton_reset = Button.new()

	boton_reset.text = "REINICIAR MISION"

	columna.add_child(boton_reset)

	boton_reset.pressed.connect(reiniciar)

	actualizar_interfaz()


# ==========================================
# ACTUALIZAR INTERFAZ
# ==========================================

func actualizar_interfaz() -> void:

	if not is_instance_valid(etiqueta_estado):
		return

	etiqueta_estado.text = "ESTADO: " + estado

	etiqueta_tiempo.text = "Tiempo: %.1f s" % tiempo

	etiqueta_altura.text = "Radio orbital visual: %.0f" % altura_orbital

	if tiempo < TIEMPO_DESPEGUE:

		etiqueta_etapa.text = "ETAPA 1: DESPEGUE"

	elif tiempo < TIEMPO_DESPEGUE + TIEMPO_ASCENSO:

		etiqueta_etapa.text = "ETAPA 2: ASCENSO"

	elif tiempo < TIEMPO_DESPEGUE + TIEMPO_ASCENSO + TIEMPO_SEPARACION:

		etiqueta_etapa.text = "ETAPA 3: SEPARACION"

	else:

		etiqueta_etapa.text = "ETAPA 4: ORBITA"


# ==========================================
# DIBUJAR ESCENARIO
# ==========================================

func _draw() -> void:

	var pantalla = get_viewport_rect().size

	# Fondo espacial

	draw_rect(
		Rect2(Vector2.ZERO, pantalla),
		Color(0.005, 0.01, 0.035)
	)

	# Estrellas

	for i in range(140):

		var x = fposmod(i * 173.0, pantalla.x)
		var y = fposmod(i * 97.0, pantalla.y)

		draw_circle(
			Vector2(x, y),
			1.2,
			Color(0.8, 0.85, 1.0)
		)

	tierra = obtener_tierra()

	# Orbita prevista

	draw_arc(
		tierra,
		altura_orbital,
		0,
		TAU,
		120,
		Color(0.1, 0.8, 1.0, 0.55),
		2.0
	)

	# Tierra

	draw_circle(
		tierra,
		78,
		Color(0.03, 0.2, 0.65)
	)

	# Continentes decorativos

	draw_circle(
		tierra + Vector2(-27, -20),
		21,
		Color(0.1, 0.48, 0.3)
	)

	draw_circle(
		tierra + Vector2(29, 18),
		18,
		Color(0.1, 0.48, 0.3)
	)

	draw_circle(
		tierra + Vector2(-5, 40),
		12,
		Color(0.1, 0.48, 0.3)
	)

	# Trayectoria del satelite

	if trayectoria.size() > 1:

		draw_polyline(
			trayectoria,
			Color.YELLOW,
			2.0
		)

	# Cohete

	if lanzado and not satelite_liberado:

		dibujar_cohete(posicion_cohete)

	# Satelite

	if satelite_liberado:

		dibujar_satelite(posicion_satelite)

	# Nombre de la Tierra

	draw_string(
		ThemeDB.fallback_font,
		tierra + Vector2(-25, 100),
		"TIERRA",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color.WHITE
	)

	# Indicador de orbita

	draw_string(
		ThemeDB.fallback_font,
		tierra + Vector2(altura_orbital + 8, -10),
		"ORBITA",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		13,
		Color.CYAN
	)


# ==========================================
# DIBUJAR COHETE
# ==========================================

func dibujar_cohete(pos: Vector2) -> void:

	# Cuerpo

	var cuerpo = PackedVector2Array([
		Vector2(0, -19),
		Vector2(9, -5),
		Vector2(9, 14),
		Vector2(-9, 14),
		Vector2(-9, -5)
	])

	var puntos = PackedVector2Array()

	for p in cuerpo:
		puntos.append(pos + p)

	draw_colored_polygon(
		puntos,
		Color.WHITE
	)

	# Ventana

	draw_circle(
		pos + Vector2(0, -4),
		4,
		Color.CYAN
	)

	# Aletas

	draw_colored_polygon(
		PackedVector2Array([
			pos + Vector2(-9, 7),
			pos + Vector2(-16, 17),
			pos + Vector2(-9, 14)
		]),
		Color.RED
	)

	draw_colored_polygon(
		PackedVector2Array([
			pos + Vector2(9, 7),
			pos + Vector2(16, 17),
			pos + Vector2(9, 14)
		]),
		Color.RED
	)

	# Llama

	if tiempo < TIEMPO_DESPEGUE + TIEMPO_ASCENSO:

		draw_colored_polygon(
			PackedVector2Array([
				pos + Vector2(-5, 14),
				pos + Vector2(0, 29),
				pos + Vector2(5, 14)
			]),
			Color.ORANGE
		)


# ==========================================
# DIBUJAR SATELITE
# ==========================================

func dibujar_satelite(pos: Vector2) -> void:

	# Cuerpo central

	draw_rect(
		Rect2(pos - Vector2(6, 6), Vector2(12, 12)),
		Color.WHITE
	)

	# Panel solar izquierdo

	draw_rect(
		Rect2(pos + Vector2(-29, -5), Vector2(19, 10)),
		Color.DODGER_BLUE
	)

	# Panel solar derecho

	draw_rect(
		Rect2(pos + Vector2(10, -5), Vector2(19, 10)),
		Color.DODGER_BLUE
	)

	# Antena

	draw_line(
		pos,
		pos + Vector2(0, -15),
		Color.WHITE,
		2.0
	)

	draw_circle(
		pos + Vector2(0, -16),
		3,
		Color.ORANGE
	)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://mision_1.tscn")
	pass # Replace with function body.
