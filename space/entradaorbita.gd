extends Control

# =====================================
# CONFIGURACION DE LA MISION
# =====================================

var tiempo_mision: float = 0.0
var velocidad_simulacion: float = 1.0

var pausada: bool = false
var iniciada: bool = false

const TIEMPO_DESPEGUE = 4.0
const TIEMPO_VIAJE = 14.0
const TIEMPO_INSERCION = 3.0

const RADIO_ORBITA_LUNAR_X = 58.0
const RADIO_ORBITA_LUNAR_Y = 40.0

var posicion_nave = Vector2.ZERO
var rotacion_nave: float = 0.0

var trayectoria: PackedVector2Array = []

var estado_mision = "READY FOR LAUNCH"

var etiqueta_estado: Label
var etiqueta_tiempo: Label
var etiqueta_velocidad: Label

var boton_lanzar: Button
var boton_pausa: Button


# =====================================
# INICIO
# =====================================

func _ready() -> void:

	crear_interfaz()
	actualizar_posicion()
	queue_redraw()


func _process(delta: float) -> void:

	if iniciada and not pausada:

		tiempo_mision += delta * velocidad_simulacion

		actualizar_posicion()
		actualizar_interfaz()

		queue_redraw()


# =====================================
# POSICIONES DEL SISTEMA
# =====================================

func obtener_tierra() -> Vector2:

	var pantalla = get_viewport_rect().size

	return Vector2(350, pantalla.y * 0.58)


func obtener_luna() -> Vector2:

	var pantalla = get_viewport_rect().size

	return Vector2(pantalla.x - 180, pantalla.y * 0.38)


func obtener_inicio() -> Vector2:

	return obtener_tierra() + Vector2(0, -65)


func obtener_orbita_tierra() -> Vector2:

	return obtener_tierra() + Vector2(0, -110)


func obtener_llegada() -> Vector2:

	return obtener_luna() + Vector2(-68, 0)


# =====================================
# CURVA DE TRANSFERENCIA
# =====================================

func calcular_transferencia(t: float) -> Vector2:

	var inicio = obtener_orbita_tierra()
	var final = obtener_llegada()

	var control = (inicio + final) / 2.0
	control.y -= 130.0

	# Curva Bezier

	var p = inicio * pow(1.0 - t, 2)
	p += control * 2.0 * (1.0 - t) * t
	p += final * pow(t, 2)

	return p


# =====================================
# POSICION DE LA NAVE
# =====================================

func actualizar_posicion() -> void:

	var tierra = obtener_tierra()
	var luna = obtener_luna()

	# ETAPA 1: DESPEGUE

	if tiempo_mision < TIEMPO_DESPEGUE:

		var t = tiempo_mision / TIEMPO_DESPEGUE
		t = smoothstep(0.0, 1.0, t)

		posicion_nave = obtener_inicio().lerp(
			obtener_orbita_tierra(), t
		)

		estado_mision = "LAUNCHING FROM EARTH"

		rotacion_nave = -PI / 2.0

	# ETAPA 2: VIAJE A LA LUNA

	elif tiempo_mision < TIEMPO_DESPEGUE + TIEMPO_VIAJE:

		var t = (
			tiempo_mision - TIEMPO_DESPEGUE
		) / TIEMPO_VIAJE

		posicion_nave = calcular_transferencia(t)

		estado_mision = "TRIP TO THE MOON"

		# Orientar nave siguiendo la trayectoria

		var siguiente = calcular_transferencia(
			min(t + 0.001, 1.0)
		)

		rotacion_nave = (
			siguiente - posicion_nave
		).angle()

	# ETAPA 3: INSERCION ORBITAL

	elif tiempo_mision < TIEMPO_DESPEGUE + TIEMPO_VIAJE + TIEMPO_INSERCION:

		var t = (
			tiempo_mision - TIEMPO_DESPEGUE - TIEMPO_VIAJE
		) / TIEMPO_INSERCION

		var angulo = PI + t * 0.35

		posicion_nave = luna + Vector2(
			cos(angulo) * RADIO_ORBITA_LUNAR_X,
			sin(angulo) * RADIO_ORBITA_LUNAR_Y
		)

		rotacion_nave = angulo + PI / 2.0

		estado_mision = "ENTERING MOON ORBIT"

	# ETAPA 4: ORBITA LUNAR

	else:

		var tiempo_orbita = (
			tiempo_mision -
			TIEMPO_DESPEGUE -
			TIEMPO_VIAJE -
			TIEMPO_INSERCION
		)

		var angulo = PI + 0.35 + tiempo_orbita * 0.65

		posicion_nave = luna + Vector2(
			cos(angulo) * RADIO_ORBITA_LUNAR_X,
			sin(angulo) * RADIO_ORBITA_LUNAR_Y
		)

		rotacion_nave = angulo + PI / 2.0

		estado_mision = "¡MOON ORBIT REACHED!"

	# Guardar trayectoria

	if trayectoria.is_empty() or posicion_nave.distance_to(
		trayectoria[trayectoria.size() - 1]
	) > 2.0:

		trayectoria.append(posicion_nave)

	if trayectoria.size() > 1500:
		trayectoria.remove_at(0)


# =====================================
# INICIAR MISION
# =====================================

func lanzar_nave() -> void:

	tiempo_mision = 0.0

	trayectoria.clear()

	iniciada = true
	pausada = false

	boton_lanzar.disabled = true
	boton_pausa.disabled = false

	boton_pausa.text = "PAUSE"

	actualizar_posicion()
	actualizar_interfaz()
	queue_redraw()


# =====================================
# PAUSAR Y REANUDAR
# =====================================

func cambiar_pausa() -> void:

	pausada = not pausada

	if pausada:

		boton_pausa.text = "CONTINUE"

	else:

		boton_pausa.text = "PAUSE"

	actualizar_interfaz()


# =====================================
# REINICIAR
# =====================================

func reiniciar() -> void:

	tiempo_mision = 0.0

	iniciada = false
	pausada = false

	trayectoria.clear()

	estado_mision = "READY FOR LAUNCH"

	boton_lanzar.disabled = false
	boton_pausa.disabled = true

	boton_pausa.text = "PAUSE"

	actualizar_posicion()
	actualizar_interfaz()

	queue_redraw()


# =====================================
# INTERFAZ
# =====================================

func crear_interfaz() -> void:

	var panel = PanelContainer.new()

	panel.position = Vector2(20, 20)
	panel.custom_minimum_size = Vector2(270, 0)

	add_child(panel)

	var columna = VBoxContainer.new()

	columna.add_theme_constant_override(
		"separation", 10
	)

	panel.add_child(columna)

	var titulo = Label.new()

	titulo.text = "MISION: EARTH - MOON"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	columna.add_child(titulo)

	columna.add_child(HSeparator.new())

	etiqueta_estado = Label.new()
	columna.add_child(etiqueta_estado)

	etiqueta_tiempo = Label.new()
	columna.add_child(etiqueta_tiempo)

	etiqueta_velocidad = Label.new()
	columna.add_child(etiqueta_velocidad)

	columna.add_child(HSeparator.new())

	# Velocidad de simulacion

	var titulo_velocidad = Label.new()
	titulo_velocidad.text = "Speed of the simulation"

	columna.add_child(titulo_velocidad)

	var slider = HSlider.new()

	slider.min_value = 0.2
	slider.max_value = 3.0
	slider.step = 0.1
	slider.value = 1.0

	columna.add_child(slider)

	slider.value_changed.connect(
		func(valor):
			velocidad_simulacion = valor
	)

	columna.add_child(HSeparator.new())

	# Boton lanzamiento

	boton_lanzar = Button.new()

	boton_lanzar.text = "LAUNCH ROCKET"

	columna.add_child(boton_lanzar)

	boton_lanzar.pressed.connect(lanzar_nave)

	# Pausa

	boton_pausa = Button.new()

	boton_pausa.text = "PAUSE"
	boton_pausa.disabled = true

	columna.add_child(boton_pausa)

	boton_pausa.pressed.connect(cambiar_pausa)

	# Reset

	var boton_reset = Button.new()

	boton_reset.text = "RESET"

	columna.add_child(boton_reset)

	boton_reset.pressed.connect(reiniciar)

	actualizar_interfaz()


# =====================================
# ACTUALIZAR INFORMACION
# =====================================

func actualizar_interfaz() -> void:

	if not is_instance_valid(etiqueta_estado):
		return

	etiqueta_estado.text = "State: " + estado_mision

	etiqueta_tiempo.text = "Time: %.1f s" % tiempo_mision

	etiqueta_velocidad.text = (
		"Simulation: %.1fx" % velocidad_simulacion
	)


# =====================================
# DIBUJAR ESCENARIO
# =====================================

func _draw() -> void:

	var pantalla = get_viewport_rect().size

	# Fondo espacial

	draw_rect(
		Rect2(Vector2.ZERO, pantalla),
		Color(0.005, 0.01, 0.035)
	)

	# Estrellas

	for i in range(120):

		var x = fposmod(i * 173.0, pantalla.x)
		var y = fposmod(i * 97.0, pantalla.y)

		draw_circle(
			Vector2(x, y),
			1.2,
			Color(0.8, 0.85, 1.0)
		)

	var tierra = obtener_tierra()
	var luna = obtener_luna()

	# Orbita terrestre

	draw_arc(
		tierra,
		110.0,
		0,
		TAU,
		100,
		Color(0.3, 0.5, 1.0, 0.5),
		1.5
	)

	# Trayectoria de transferencia

	var puntos = PackedVector2Array()

	for i in range(101):

		puntos.append(
			calcular_transferencia(float(i) / 100.0)
		)

	draw_polyline(
		puntos,
		Color(0.2, 0.7, 1.0, 0.4),
		2.0
	)

	# Orbita lunar

	draw_arc(
		luna,
		RADIO_ORBITA_LUNAR_X,
		0,
		TAU,
		100,
		Color.CYAN,
		2.0
	)

	# Tierra

	draw_circle(
		tierra,
		65,
		Color(0.05, 0.25, 0.75)
	)

	draw_circle(
		tierra + Vector2(-20, -15),
		19,
		Color(0.1, 0.55, 0.3)
	)

	draw_circle(
		tierra + Vector2(22, 18),
		16,
		Color(0.1, 0.55, 0.3)
	)

	# Luna

	draw_circle(
		luna,
		28,
		Color(0.72, 0.72, 0.75)
	)

	draw_circle(
		luna + Vector2(9, -8),
		5,
		Color(0.48, 0.48, 0.5)
	)

	draw_circle(
		luna + Vector2(-10, 7),
		4,
		Color(0.48, 0.48, 0.5)
	)

	# Trayectoria recorrida

	if trayectoria.size() > 1:

		draw_polyline(
			trayectoria,
			Color.YELLOW,
			2.5
		)

	# Nave

	if iniciada:

		dibujar_nave(
			posicion_nave,
			rotacion_nave
		)

	# Nombres

	draw_string(
		ThemeDB.fallback_font,
		tierra + Vector2(-25, 85),
		"EARTH",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color.WHITE
	)

	draw_string(
		ThemeDB.fallback_font,
		luna + Vector2(-20, 48),
		"MOON",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color.WHITE
	)


# =====================================
# DIBUJAR NAVE ESPACIAL
# =====================================

func dibujar_nave(pos: Vector2, rotacion: float) -> void:

	var cuerpo = PackedVector2Array()

	cuerpo.append(Vector2(15, 0))
	cuerpo.append(Vector2(-9, -7))
	cuerpo.append(Vector2(-6, 0))
	cuerpo.append(Vector2(-9, 7))

	var cuerpo_rotado = PackedVector2Array()

	for punto in cuerpo:

		cuerpo_rotado.append(
			pos + punto.rotated(rotacion)
		)

	# Cuerpo de la nave

	draw_colored_polygon(
		cuerpo_rotado,
		Color.WHITE
	)

	# Ventana

	draw_circle(
		pos + Vector2(3, 0).rotated(rotacion),
		2.5,
		Color.CYAN
	)

	# Llamas del motor

	if tiempo_mision < TIEMPO_DESPEGUE or (
		tiempo_mision >= TIEMPO_DESPEGUE + TIEMPO_VIAJE
		and tiempo_mision < TIEMPO_DESPEGUE + TIEMPO_VIAJE + TIEMPO_INSERCION
	):

		var llama = PackedVector2Array()

		llama.append(
			pos + Vector2(-8, -3).rotated(rotacion)
		)

		llama.append(
			pos + Vector2(-19, 0).rotated(rotacion)
		)

		llama.append(
			pos + Vector2(-8, 3).rotated(rotacion)
		)

		draw_colored_polygon(
			llama,
			Color.ORANGE
		)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://mision2.tscn")
	
	pass # Replace with function body.
