class_name CajaDialogo
extends Control
## Caja de diálogo: texto con efecto de máquina de escribir, nombre, retrato
## del personaje y opciones de respuesta con teclado o mouse.
##
## Cada línea es un Dictionary: {"nombre": "Don Chente", "texto": "...", "retrato": Texture2D o ruta}.
## El texto acepta BBCode, por ejemplo "[color=#e05050]Tezcatlipoca[/color]".

signal _linea_leida
signal opcion_elegida(indice: int)

## Letras por segundo del efecto de máquina de escribir.
const VELOCIDAD_LETRAS := 45.0
## Tiempo en que se ignoran las teclas al abrir una línea, para no saltarla con la misma tecla.
const PAUSA_ENTRADA := 0.15
## Altura de la caja sin opciones y espacio extra por cada opción.
const ALTO_CAJA := 194
const ALTO_OPCION := 48

var _nombre: Label
var _texto: RichTextLabel
var _opciones: VBoxContainer
var _continuar: Label
var _panel_retrato: PanelContainer
var _retrato: TextureRect
var _nombre_retrato: Label

var _letras: float = 0.0
var _escribiendo: bool = false
var _opciones_pendientes: Array = []
var _pausa: float = 0.0
var _cancelado: bool = false


func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_left = 24
	offset_right = -24
	offset_bottom = -20
	offset_top = offset_bottom - ALTO_CAJA
	var fila := HBoxContainer.new()
	fila.set_anchors_preset(Control.PRESET_FULL_RECT)
	fila.add_theme_constant_override("separation", 12)
	add_child(fila)

	var panel_texto := PanelContainer.new()
	panel_texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_texto.add_theme_stylebox_override("panel", EstiloUI.panel())
	panel_texto.gui_input.connect(_al_clic)
	fila.add_child(panel_texto)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 6)
	panel_texto.add_child(columna)
	_nombre = EstiloUI.etiqueta("", 22, EstiloUI.NOMBRE)
	columna.add_child(_nombre)
	_texto = RichTextLabel.new()
	_texto.bbcode_enabled = true
	_texto.scroll_active = false
	_texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texto.add_theme_font_size_override("normal_font_size", 21)
	_texto.add_theme_color_override("default_color", EstiloUI.TEXTO)
	columna.add_child(_texto)
	_opciones = VBoxContainer.new()
	_opciones.add_theme_constant_override("separation", 4)
	columna.add_child(_opciones)
	_continuar = EstiloUI.etiqueta("[E] Continuar", 15, EstiloUI.TENUE)
	_continuar.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	columna.add_child(_continuar)

	_panel_retrato = PanelContainer.new()
	_panel_retrato.custom_minimum_size = Vector2(178, 0)
	_panel_retrato.add_theme_stylebox_override("panel", EstiloUI.panel(3, 8))
	fila.add_child(_panel_retrato)
	var columna_retrato := VBoxContainer.new()
	_panel_retrato.add_child(columna_retrato)
	_retrato = TextureRect.new()
	_retrato.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	columna_retrato.add_child(_retrato)
	_nombre_retrato = EstiloUI.etiqueta("", 17, EstiloUI.NOMBRE)
	_nombre_retrato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna_retrato.add_child(_nombre_retrato)


## Muestra las líneas una por una y termina cuando el jugador lee la última.
func reproducir(lineas: Array) -> void:
	_cancelado = false
	visible = true
	for linea in lineas:
		_mostrar_linea(linea, [])
		await _linea_leida
		if _cancelado:
			break
	visible = false


## Muestra una línea con opciones y regresa el índice de la opción elegida
## (o -1 si el diálogo se cancela, por ejemplo por un Game Over).
func preguntar(linea: Dictionary, opciones: Array) -> int:
	_cancelado = false
	visible = true
	_mostrar_linea(linea, opciones)
	var indice: int = await opcion_elegida
	visible = false
	return indice


## Cierra el diálogo que esté abierto y termina sus await pendientes.
func cancelar() -> void:
	if not visible:
		return
	_cancelado = true
	_opciones_pendientes = []
	_limpiar_opciones()
	visible = false
	_linea_leida.emit()
	opcion_elegida.emit(-1)


## true mientras el texto se sigue escribiendo.
func esta_escribiendo() -> bool:
	return _escribiendo


func _mostrar_linea(linea: Dictionary, opciones: Array) -> void:
	var nombre: String = linea.get("nombre", "")
	_nombre.text = nombre
	_nombre.visible = nombre != ""
	_texto.text = linea.get("texto", "")
	_texto.visible_characters = 0
	_letras = 0.0
	_escribiendo = true
	_pausa = PAUSA_ENTRADA
	_opciones_pendientes = opciones
	_limpiar_opciones()
	offset_top = offset_bottom - ALTO_CAJA - ALTO_OPCION * opciones.size()
	_continuar.visible = false
	var retrato: Variant = linea.get("retrato", null)
	if retrato is String and retrato != "":
		retrato = load(retrato)
	_retrato.texture = retrato if retrato is Texture2D else null
	_nombre_retrato.text = nombre
	_panel_retrato.visible = _retrato.texture != null


func _process(delta: float) -> void:
	if not visible:
		return
	_pausa = maxf(_pausa - delta, 0.0)
	if _escribiendo:
		_letras += VELOCIDAD_LETRAS * delta
		var visibles := int(_letras)
		if visibles != _texto.visible_characters:
			_texto.visible_characters = visibles
			if visibles % 2 == 0:
				Audio.reproducir("letra", 0.0, randf_range(0.95, 1.05))
		if _texto.visible_characters >= _texto.get_total_character_count():
			_terminar_escritura()


func _terminar_escritura() -> void:
	_escribiendo = false
	_texto.visible_characters = -1
	if _opciones_pendientes.is_empty():
		_continuar.visible = true
		return
	for i in _opciones_pendientes.size():
		var boton := EstiloUI.boton(str(_opciones_pendientes[i]))
		boton.pressed.connect(_elegir.bind(i))
		_opciones.add_child(boton)
	(_opciones.get_child(0) as Button).grab_focus()


func _avanzar() -> void:
	if _pausa > 0.0:
		return
	if _escribiendo:
		_terminar_escritura()
	elif _opciones_pendientes.is_empty():
		_linea_leida.emit()
	else:
		var foco := get_viewport().gui_get_focus_owner()
		if foco is Button and foco.get_parent() == _opciones:
			(foco as Button).pressed.emit()


func _elegir(indice: int) -> void:
	if _pausa > 0.0:
		return
	_opciones_pendientes = []
	_limpiar_opciones()
	opcion_elegida.emit(indice)


func _limpiar_opciones() -> void:
	for hijo in _opciones.get_children():
		_opciones.remove_child(hijo)
		hijo.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interactuar") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_avanzar()


func _al_clic(event: InputEvent) -> void:
	var clic := event as InputEventMouseButton
	if clic and clic.pressed and clic.button_index == MOUSE_BUTTON_LEFT:
		_avanzar()
