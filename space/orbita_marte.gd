
extends Control

# ==================================================
# EARTH TO MARS - INTERPLANETARY MISSION SIMULATOR
# ==================================================

# UNIDADES:
# Distancia: AU
# Tiempo: dias
# Velocidad: km/s

const AU_KM = 149597870.7
const SEGUNDOS_DIA = 86400.0

const RADIO_TIERRA = 1.0
const RADIO_MARTE = 1.524

const PERIODO_TIERRA = 365.256
const PERIODO_MARTE = 687.0

const MU_SOL = 0.0002959122

# Transferencia de Hohmann

const A_TRANSFERENCIA = (RADIO_TIERRA + RADIO_MARTE) / 2.0

const EXCENTRICIDAD = (
	RADIO_MARTE - RADIO_TIERRA
) / (
	RADIO_MARTE + RADIO_TIERRA
)

const TIEMPO_TRANSFERENCIA = (
	PI * sqrt(pow(A_TRANSFERENCIA, 3) / MU_SOL)
)

# ==================================================
# VARIABLES
# ==================================================

var tiempo: float = 0.0

var velocidad_simulacion: float = 1.0

var iniciada: bool = false
var pausada: bool = false
var llegada: bool = false

var posicion_tierra = Vector2.ZERO
var posicion_marte = Vector2.ZERO
var posicion_nave = Vector2.ZERO

var angulo_tierra: float = 0.0
var angulo_marte: float = 0.0

var trayectoria: PackedVector2Array = []

var estado_mision: String = "LISTO PARA LANZAR"

var etiqueta_estado: Label
var etiqueta_tiempo: Label
var etiqueta_distancia: Label
var etiqueta_velocidad: Label
var etiqueta_progreso: Label
var etiqueta_fase: Label
var etiqueta_dv: Label

var boton_lanzar: Button
var boton_pausa: Button

# Radio visual exagerado para mostrar la orbita marciana
const RADIO_VISUAL_ORBITA_MARTE = 0.045


# ==================================================
# INICIO
# ==================================================

func _ready() -> void:

	crear_interfaz()

	calcular_posiciones()

	actualizar_interfaz()

	queue_redraw()


func _process(delta: float) -> void:

	if iniciada and not pausada:

		tiempo += delta * velocidad_simulacion

		calcular_posiciones()

		actualizar_interfaz()

		queue_redraw()


# ==================================================
# CALCULAR POSICION DE LOS PLANETAS
# ==================================================

func calcular_posiciones() -> void:

	var velocidad_tierra = TAU / PERIODO_TIERRA

	var velocidad_marte = TAU / PERIODO_MARTE

	# La posicion inicial de Marte se calcula
	# para que coincida con la nave al llegar.

	var fase_inicial_marte = (
		PI - velocidad_marte * TIEMPO_TRANSFERENCIA
	)

	angulo_tierra = velocidad_tierra * tiempo

	angulo_marte = (
		fase_inicial_marte +
		velocidad_marte * tiempo
	)

	posicion_tierra = Vector2(
		cos(angulo_tierra),
		sin(angulo_tierra)
	) * RADIO_TIERRA

	posicion_marte = Vector2(
		cos(angulo_marte),
		sin(angulo_marte)
	) * RADIO_MARTE

	# ==================================
	# NAVE EN TRANSFERENCIA
	# ==================================

	if tiempo < TIEMPO_TRANSFERENCIA:

		var M = PI * tiempo / TIEMPO_TRANSFERENCIA

		var E = resolver_kepler(M)

		var x = A_TRANSFERENCIA * (cos(E) - EXCENTRICIDAD)

		var y = A_TRANSFERENCIA * sqrt(
			1.0 - EXCENTRICIDAD * EXCENTRICIDAD
		) * sin(E)

		posicion_nave = Vector2(x, y)

		estado_mision = "CRUCERO INTERPLANETARIO"

		llegada = false

	# ==================================
	# INSERCION EN ORBITA MARCIANA
	# ==================================

	else:

		llegada = true

		var tiempo_orbita = tiempo - TIEMPO_TRANSFERENCIA

		var angulo_orbita = tiempo_orbita * 0.35

		posicion_nave = posicion_marte + Vector2(
			cos(angulo_orbita),
			sin(angulo_orbita)
		) * RADIO_VISUAL_ORBITA_MARTE

		estado_mision = "¡ORBITA DE MARTE ALCANZADA!"

	# ==================================
	# TRAYECTORIA
	# ==================================

	if trayectoria.is_empty():

		trayectoria.append(posicion_nave)

	elif posicion_nave.distance_to(
		trayectoria[trayectoria.size() - 1]
	) > 0.003:

		trayectoria.append(posicion_nave)

	if trayectoria.size() > 3000:

		trayectoria.remove_at(0)


# ==================================================
# RESOLVER ECUACION DE KEPLER
# ==================================================

func resolver_kepler(M: float) -> float:

	var E = M

	for i in range(20):

		var f = E - EXCENTRICIDAD * sin(E) - M

		var df = 1.0 - EXCENTRICIDAD * cos(E)

		E -= f / df

	return E


# ==================================================
# CALCULAR VELOCIDADES Y DELTA V
# ==================================================

func velocidad_circular(radio: float) -> float:

	return sqrt(MU_SOL / radio) * AU_KM / SEGUNDOS_DIA


func calcular_delta_v_salida() -> float:

	var velocidad_tierra = velocidad_circular(RADIO_TIERRA)

	var velocidad_transferencia = sqrt(
		MU_SOL * (
			2.0 / RADIO_TIERRA -
			1.0 / A_TRANSFERENCIA
		)
	) * AU_KM / SEGUNDOS_DIA

	return velocidad_transferencia - velocidad_tierra


func calcular_delta_v_llegada() -> float:

	var velocidad_marte = velocidad_circular(RADIO_MARTE)

	var velocidad_transferencia = sqrt(
		MU_SOL * (
			2.0 / RADIO_MARTE -
			1.0 / A_TRANSFERENCIA
		)
	) * AU_KM / SEGUNDOS_DIA

	return velocidad_marte - velocidad_transferencia


# ==================================================
# LANZAMIENTO
# ==================================================

func lanzar_mision() -> void:

	tiempo = 0.0

	trayectoria.clear()

	iniciada = true
	pausada = false
	llegada = false

	boton_lanzar.disabled = true
	boton_pausa.disabled = false

	boton_pausa.text = "PAUSAR"

	calcular_posiciones()

	actualizar_interfaz()

	queue_redraw()


# ==================================================
# PAUSAR
# ==================================================

func cambiar_pausa() -> void:

	if not iniciada:
		return

	pausada = not pausada

	if pausada:

		boton_pausa.text = "REANUDAR"

	else:

		boton_pausa.text = "PAUSAR"

	actualizar_interfaz()


# ==================================================
# REINICIAR
# ==================================================

func reiniciar() -> void:

	tiempo = 0.0

	iniciada = false
	pausada = false
	llegada = false

	trayectoria.clear()

	estado_mision = "LISTO PARA LANZAR"

	boton_lanzar.disabled = false
	boton_pausa.disabled = true

	boton_pausa.text = "PAUSAR"

	calcular_posiciones()

	actualizar_interfaz()

	queue_redraw()


# ==================================================
# AVANZAR 30 DIAS
# ==================================================

func avanzar_30_dias() -> void:

	if not iniciada or pausada:
		return

	tiempo += 30.0

	calcular_posiciones()

	actualizar_interfaz()

	queue_redraw()


# ==================================================
# CREAR INTERFAZ
# ==================================================

func crear_interfaz() -> void:

	var panel = PanelContainer.new()

	panel.position = Vector2(18, 18)

	panel.custom_minimum_size = Vector2(315, 0)

	add_child(panel)

	var columna = VBoxContainer.new()

	columna.add_theme_constant_override(
		"separation", 9
	)

	panel.add_child(columna)

	# TITULO

	var titulo = Label.new()

	titulo.text = "INTERPLANETARY MISSION"

	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	columna.add_child(titulo)

	var subtitulo = Label.new()

	subtitulo.text = "EARTH TO MARS"

	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	columna.add_child(subtitulo)

	columna.add_child(HSeparator.new())

	# ESTADO

	etiqueta_estado = Label.new()

	etiqueta_estado.text = estado_mision

	columna.add_child(etiqueta_estado)

	etiqueta_fase = Label.new()

	columna.add_child(etiqueta_fase)

	columna.add_child(HSeparator.new())

	# DATOS DE MISION

	var titulo_datos = Label.new()

	titulo_datos.text = "MISSION TELEMETRY"

	columna.add_child(titulo_datos)

	etiqueta_tiempo = Label.new()

	columna.add_child(etiqueta_tiempo)

	etiqueta_distancia = Label.new()

	columna.add_child(etiqueta_distancia)

	etiqueta_velocidad = Label.new()

	columna.add_child(etiqueta_velocidad)

	etiqueta_progreso = Label.new()

	columna.add_child(etiqueta_progreso)

	columna.add_child(HSeparator.new())

	# DATOS ORBITALES

	var titulo_orbital = Label.new()

	titulo_orbital.text = "ORBITAL MECHANICS"

	columna.add_child(titulo_orbital)

	var etiqueta_excentricidad = Label.new()

	etiqueta_excentricidad.text = (
		"Excentricidad: %.4f" % EXCENTRICIDAD
	)

	columna.add_child(etiqueta_excentricidad)

	var etiqueta_semieje = Label.new()

	etiqueta_semieje.text = (
		"Semieje mayor: %.3f AU" % A_TRANSFERENCIA
	)

	columna.add_child(etiqueta_semieje)

	etiqueta_dv = Label.new()

	columna.add_child(etiqueta_dv)

	columna.add_child(HSeparator.new())

	# VELOCIDAD DE SIMULACION

	var titulo_velocidad = Label.new()

	titulo_velocidad.text = "VELOCIDAD DE SIMULACION"

	columna.add_child(titulo_velocidad)

	var slider = HSlider.new()

	slider.min_value = 0.2
	slider.max_value = 20.0
	slider.step = 0.2
	slider.value = velocidad_simulacion

	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	columna.add_child(slider)

	slider.value_changed.connect(
		func(valor):
			velocidad_simulacion = valor
			actualizar_interfaz()
	)

	columna.add_child(HSeparator.new())

	# BOTON LANZAMIENTO

	boton_lanzar = Button.new()

	boton_lanzar.text = "INICIAR MISION"

	columna.add_child(boton_lanzar)

	boton_lanzar.pressed.connect(lanzar_mision)

	# PAUSA

	boton_pausa = Button.new()

	boton_pausa.text = "PAUSAR"

	boton_pausa.disabled = true

	columna.add_child(boton_pausa)

	boton_pausa.pressed.connect(cambiar_pausa)

	# AVANZAR

	var boton_avanzar = Button.new()

	boton_avanzar.text = "AVANZAR 30 DIAS"

	columna.add_child(boton_avanzar)

	boton_avanzar.pressed.connect(avanzar_30_dias)

	# RESET

	var boton_reset = Button.new()

	boton_reset.text = "REINICIAR MISION"

	columna.add_child(boton_reset)

	boton_reset.pressed.connect(reiniciar)

	actualizar_interfaz()


# ==================================================
# ACTUALIZAR DATOS
# ==================================================

func actualizar_interfaz() -> void:

	if not is_instance_valid(etiqueta_estado):
		return

	etiqueta_estado.text = "ESTADO: " + estado_mision

	etiqueta_tiempo.text = "Tiempo: %.1f dias" % tiempo

	var distancia = posicion_nave.distance_to(posicion_marte)

	etiqueta_distancia.text = (
		"Distancia a Marte: %.3f AU" % distancia
	)

	var porcentaje = min(
		tiempo / TIEMPO_TRANSFERENCIA * 100.0,
		100.0
	)

	etiqueta_progreso.text = (
		"Transferencia: %.1f%%" % porcentaje
	)

	etiqueta_velocidad.text = (
		"Velocidad simulacion: %.1fx" %
		velocidad_simulacion
	)

	if tiempo < TIEMPO_TRANSFERENCIA:

		etiqueta_fase.text = "FASE: TRANSFERENCIA"

	else:

		etiqueta_fase.text = "FASE: ORBITA MARCIANA"

	etiqueta_dv.text = (
		"Delta-V salida: %.2f km/s\nDelta-V llegada: %.2f km/s" %
		[
			calcular_delta_v_salida(),
			abs(calcular_delta_v_llegada())
		]
	)


# ==================================================
# CONVERSION DE COORDENADAS
# ==================================================

func escala_visual() -> float:

	var pantalla = get_viewport_rect().size

	return min(
		pantalla.x * 0.29,
		pantalla.y * 0.39
	)


func centro_sistema() -> Vector2:

	var pantalla = get_viewport_rect().size

	return Vector2(
		pantalla.x * 0.62,
		pantalla.y * 0.54
	)


func convertir_posicion(pos: Vector2) -> Vector2:

	var centro = centro_sistema()

	var escala = escala_visual()

	return centro + Vector2(
		pos.x * escala,
		-pos.y * escala
	)


# ==================================================
# DIBUJAR ESCENARIO
# ==================================================

func _draw() -> void:

	var pantalla = get_viewport_rect().size

	# FONDO

	draw_rect(
		Rect2(Vector2.ZERO, pantalla),
		Color(0.005, 0.008, 0.025)
	)

	# ESTRELLAS

	for i in range(160):

		var x = fposmod(i * 173.0, pantalla.x)

		var y = fposmod(i * 97.0, pantalla.y)

		draw_circle(
			Vector2(x, y),
			1.1,
			Color(0.75, 0.82, 1.0)
		)

	var centro = centro_sistema()

	var escala = escala_visual()

	# SOL

	draw_circle(
		centro,
		19,
		Color(1.0, 0.65, 0.12)
	)

	draw_circle(
		centro,
		26,
		Color(1.0, 0.65, 0.12, 0.15)
	)

	# ORBITA TIERRA

	draw_arc(
		centro,
		RADIO_TIERRA * escala,
		0,
		TAU,
		150,
		Color(0.3, 0.55, 1.0, 0.45),
		1.5
	)

	# ORBITA MARTE

	draw_arc(
		centro,
		RADIO_MARTE * escala,
		0,
		TAU,
		150,
		Color(1.0, 0.35, 0.25, 0.45),
		1.5
	)

	# TRANSFERENCIA DE HOHMANN

	var puntos = PackedVector2Array()

	for i in range(121):

		var E = PI * float(i) / 120.0

		var x = A_TRANSFERENCIA * (
			cos(E) - EXCENTRICIDAD
		)

		var y = A_TRANSFERENCIA * sqrt(
			1.0 - EXCENTRICIDAD * EXCENTRICIDAD
		) * sin(E)

		puntos.append(
			convertir_posicion(Vector2(x, y))
		)

	draw_polyline(
		puntos,
		Color(0.0, 0.85, 1.0, 0.55),
		2.0
	)

	# TIERRA

	var tierra_pantalla = convertir_posicion(
		posicion_tierra
	)

	draw_circle(
		tierra_pantalla,
		12,
		Color(0.05, 0.3, 0.9)
	)

	draw_circle(
		tierra_pantalla + Vector2(-4, -3),
		5,
		Color(0.1, 0.65, 0.35)
	)

	draw_circle(
		tierra_pantalla + Vector2(5, 4),
		4,
		Color(0.1, 0.65, 0.35)
	)

	# MARTE

	var marte_pantalla = convertir_posicion(
		posicion_marte
	)

	draw_circle(
		marte_pantalla,
		9,
		Color(0.85, 0.25, 0.12)
	)

	draw_circle(
		marte_pantalla + Vector2(3, -3),
		3,
		Color(1.0, 0.55, 0.3)
	)

	# ORBITA VISUAL DE MARTE

	if llegada:

		draw_arc(
			marte_pantalla,
			RADIO_VISUAL_ORBITA_MARTE * escala,
			0,
			TAU,
			100,
			Color.CYAN,
			2.0
		)

	# TRAYECTORIA RECORRIDA

	if trayectoria.size() > 1:

		var puntos_recorridos = PackedVector2Array()

		for punto in trayectoria:

			puntos_recorridos.append(
				convertir_posicion(punto)
			)

		draw_polyline(
			puntos_recorridos,
			Color.YELLOW,
			2.5
		)

	# NAVE

	if iniciada:

		var nave_pantalla = convertir_posicion(
			posicion_nave
		)

		dibujar_nave(nave_pantalla)

	# ETIQUETAS

	draw_string(
		ThemeDB.fallback_font,
		centro + Vector2(-15, 35),
		"SOL",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		13,
		Color.WHITE
	)

	draw_string(
		ThemeDB.fallback_font,
		tierra_pantalla + Vector2(-20, 25),
		"TIERRA",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		13,
		Color.WHITE
	)

	draw_string(
		ThemeDB.fallback_font,
		marte_pantalla + Vector2(-15, 22),
		"MARTE",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		13,
		Color.WHITE
	)


# ==================================================
# DIBUJAR NAVE ESPACIAL
# ==================================================

func dibujar_nave(pos: Vector2) -> void:

	var direccion = Vector2(
		posicion_marte.x - posicion_nave.x,
		posicion_marte.y - posicion_nave.y
	)

	if direccion.length() < 0.001:
		direccion = Vector2.RIGHT

	direccion = direccion.normalized()

	# La nave apunta hacia su destino

	var angulo = Vector2(
		direccion.x,
		-direccion.y
	).angle()

	var forma = PackedVector2Array([
		Vector2(0, -13),
		Vector2(8, 8),
		Vector2(0, 4),
		Vector2(-8, 8)
	])

	var puntos = PackedVector2Array()

	for punto in forma:

		puntos.append(
			pos + punto.rotated(angulo + PI / 2.0)
		)

	draw_colored_polygon(
		puntos,
		Color.WHITE
	)

	# Ventana

	draw_circle(
		pos + Vector2(0, -3).rotated(angulo + PI / 2.0),
		2.5,
		Color.CYAN
	)

	# Paneles solares

	var izquierda = Vector2(-16, 0).rotated(
		angulo + PI / 2.0
	)

	var derecha = Vector2(16, 0).rotated(
		angulo + PI / 2.0
	)

	draw_rect(
		Rect2(pos + izquierda - Vector2(5, 3), Vector2(10, 6)),
		Color.DODGER_BLUE
	)

	draw_rect(
		Rect2(pos + derecha - Vector2(5, 3), Vector2(10, 6)),
		Color.DODGER_BLUE
	)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://mision_3.tscn")
	pass # Replace with function body.
