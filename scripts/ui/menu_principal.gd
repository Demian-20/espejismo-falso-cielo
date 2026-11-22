extends Control
## Menú principal (issue #28): Nueva partida, Cargar partida, Configuración y Salir.
## Es la escena principal del proyecto. La interfaz se arma en código con EstiloUI,
## igual que el resto de la UI.

const ESCENA_INTRO := "res://scenes/intro.tscn"
const FONDO := preload("res://assets/intro/01_hermosillo_atardecer.jpg")
const VERSION := "v0.2.0-beta"

var _principal: VBoxContainer
var _configuracion: PanelContainer
var _como_jugar: PanelComoJugar
var _boton_ayuda: Button
var _nueva: Button
var _cargar: Button
var _ajustes: Button
var _salir: Button
var _detalle_cargar: Label
var _musica: HSlider
var _efectos: HSlider
var _pantalla: CheckButton
var _volver: Button
var _telon: ColorRect
var _saliendo: bool = false


func _ready() -> void:
	get_tree().paused = false
	HUD.salir_del_juego()
	Audio.musica("plaza_tarde")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_armar_fondo()
	_armar_principal()
	_armar_configuracion()
	_armar_como_jugar()
	_telon = ColorRect.new()
	_telon.color = Color(0, 0, 0, 1)
	_telon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_telon.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_telon)
	var entrada := create_tween()
	entrada.tween_property(_telon, "color:a", 0.0, 0.8)
	_mostrar_principal()


func _unhandled_input(event: InputEvent) -> void:
	var atras := event.is_action_pressed("ui_cancel") or event.is_action_pressed("pausa")
	if atras and _configuracion.visible:
		get_viewport().set_input_as_handled()
		_mostrar_principal()
	elif atras and _como_jugar.visible:
		get_viewport().set_input_as_handled()
		_como_jugar.cerrar()


func _armar_fondo() -> void:
	var imagen := TextureRect.new()
	imagen.texture = FONDO
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	imagen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(imagen)
	# Oscurece la izquierda, donde va el menú, para que se lea bien.
	var degradado := Gradient.new()
	degradado.set_color(0, Color(0.03, 0.02, 0.04, 0.92))
	degradado.set_color(1, Color(0.03, 0.02, 0.04, 0.15))
	var textura := GradientTexture2D.new()
	textura.gradient = degradado
	textura.fill_from = Vector2(0.0, 0.5)
	textura.fill_to = Vector2(0.85, 0.5)
	var sombra := TextureRect.new()
	sombra.texture = textura
	sombra.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sombra.stretch_mode = TextureRect.STRETCH_SCALE
	sombra.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sombra)
	var pie := EstiloUI.etiqueta("%s   |   UTH · Creación de Videojuegos" % VERSION, 14, EstiloUI.TENUE)
	pie.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	pie.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	pie.grow_vertical = Control.GROW_DIRECTION_BEGIN
	pie.offset_right = -24
	pie.offset_bottom = -16
	add_child(pie)


func _armar_principal() -> void:
	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	margen.offset_right = 520
	margen.add_theme_constant_override("margin_left", 72)
	add_child(margen)
	_principal = VBoxContainer.new()
	_principal.alignment = BoxContainer.ALIGNMENT_CENTER
	_principal.add_theme_constant_override("separation", 12)
	margen.add_child(_principal)
	var titulo := EstiloUI.etiqueta("ESPEJISMO", 64, EstiloUI.NOMBRE)
	titulo.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02))
	titulo.add_theme_constant_override("outline_size", 10)
	_principal.add_child(titulo)
	var subtitulo := EstiloUI.etiqueta("FALSO CIELO", 30, EstiloUI.TEXTO)
	subtitulo.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02))
	subtitulo.add_theme_constant_override("outline_size", 6)
	_principal.add_child(subtitulo)
	var capitulo := EstiloUI.etiqueta("Prólogo: Plaza Zaragoza, Hermosillo", 16, EstiloUI.TENUE)
	_principal.add_child(capitulo)
	var espacio := Control.new()
	espacio.custom_minimum_size = Vector2(0, 28)
	_principal.add_child(espacio)
	_nueva = _boton("Nueva partida", _al_nueva_partida)
	_cargar = _boton("Cargar partida", _al_cargar_partida)
	_detalle_cargar = EstiloUI.etiqueta("", 13, EstiloUI.TENUE)
	_boton_ayuda = _boton("Cómo jugar", _mostrar_como_jugar)
	_ajustes = _boton("Configuración", _mostrar_configuracion)
	_salir = _boton("Salir", _al_salir)
	_principal.add_child(_nueva)
	_principal.add_child(_cargar)
	_principal.add_child(_detalle_cargar)
	_principal.add_child(_boton_ayuda)
	_principal.add_child(_ajustes)
	_principal.add_child(_salir)
	# En la web no se puede cerrar la pestaña desde el juego.
	_salir.visible = not OS.has_feature("web")
	var ayuda := EstiloUI.etiqueta("Flechas o mouse para elegir · Enter o clic para aceptar", 13, EstiloUI.TENUE)
	_principal.add_child(ayuda)


func _armar_configuracion() -> void:
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	_configuracion = PanelContainer.new()
	_configuracion.add_theme_stylebox_override("panel", EstiloUI.panel(3, 28))
	_configuracion.visible = false
	centro.add_child(_configuracion)
	var columna := VBoxContainer.new()
	columna.custom_minimum_size = Vector2(460, 0)
	columna.add_theme_constant_override("separation", 14)
	_configuracion.add_child(columna)
	var titulo := EstiloUI.etiqueta("CONFIGURACIÓN", 32, EstiloUI.NOMBRE)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(titulo)
	_musica = _deslizador(columna, "Volumen de la música", Configuracion.volumen_musica)
	_musica.value_changed.connect(_al_cambiar_musica)
	_efectos = _deslizador(columna, "Volumen de los efectos", Configuracion.volumen_efectos)
	_efectos.value_changed.connect(_al_cambiar_efectos)
	_pantalla = CheckButton.new()
	_pantalla.text = "Pantalla completa"
	_pantalla.button_pressed = Configuracion.pantalla_completa
	_pantalla.add_theme_font_size_override("font_size", 20)
	for estado in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		_pantalla.add_theme_color_override(estado, EstiloUI.TEXTO)
	_pantalla.toggled.connect(_al_cambiar_pantalla)
	columna.add_child(_pantalla)
	_volver = EstiloUI.boton("Volver")
	_volver.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_volver.pressed.connect(_mostrar_principal)
	columna.add_child(_volver)
	var ayuda := EstiloUI.etiqueta("[Esc] Volver", 13, EstiloUI.TENUE)
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(ayuda)


func _armar_como_jugar() -> void:
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	_como_jugar = PanelComoJugar.new()
	_como_jugar.visible = false
	_como_jugar.cerrado.connect(_mostrar_principal)
	centro.add_child(_como_jugar)


func _mostrar_como_jugar() -> void:
	_principal.visible = false
	_como_jugar.abrir()


func _mostrar_principal() -> void:
	if _configuracion.visible:
		Configuracion.guardar()
	_configuracion.visible = false
	_principal.visible = true
	var hay := GameState.hay_partida_guardada()
	_cargar.disabled = not hay
	_cargar.focus_mode = Control.FOCUS_ALL if hay else Control.FOCUS_NONE
	_cargar.modulate.a = 1.0 if hay else 0.45
	_detalle_cargar.text = ("Guardada: " + GameState.fecha_partida_guardada()) if hay else "No hay partida guardada"
	_nueva.grab_focus()


func _mostrar_configuracion() -> void:
	_principal.visible = false
	_configuracion.visible = true
	_musica.grab_focus()


func _al_nueva_partida() -> void:
	if _saliendo:
		return
	GameState.nueva_partida()
	_ir_a(ESCENA_INTRO)


func _al_cargar_partida() -> void:
	if _saliendo or not GameState.hay_partida_guardada():
		return
	var escena := GameState.cargar_partida()
	if escena == "" or not ResourceLoader.exists(escena):
		_detalle_cargar.text = "No se pudo leer la partida guardada"
		return
	_ir_a(escena)


func _al_salir() -> void:
	get_tree().quit()


func _ir_a(escena: String) -> void:
	_saliendo = true
	var tween := create_tween()
	tween.tween_property(_telon, "color:a", 1.0, 0.6)
	await tween.finished
	HUD.entrar_al_juego()
	get_tree().change_scene_to_file(escena)


func _al_cambiar_musica(valor: float) -> void:
	Configuracion.volumen_musica = valor
	Configuracion.aplicar(false)


func _al_cambiar_efectos(valor: float) -> void:
	Configuracion.volumen_efectos = valor
	Configuracion.aplicar(false)
	Audio.reproducir("seleccionar")


func _al_cambiar_pantalla(activo: bool) -> void:
	Configuracion.pantalla_completa = activo
	Configuracion.aplicar()


func _boton(texto: String, accion: Callable) -> Button:
	var b := EstiloUI.boton(texto)
	b.custom_minimum_size = Vector2(300, 0)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(accion)
	return b


func _deslizador(columna: VBoxContainer, texto: String, valor: float) -> HSlider:
	columna.add_child(EstiloUI.etiqueta(texto, 18, EstiloUI.TEXTO))
	var d := HSlider.new()
	d.min_value = 0.0
	d.max_value = 1.0
	d.step = 0.05
	d.value = valor
	d.custom_minimum_size = Vector2(0, 24)
	columna.add_child(d)
	return d
