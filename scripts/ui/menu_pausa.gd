class_name MenuPausa
extends CanvasLayer
## Menú de pausa (Esc o P): continuar, guardar la partida, reintentar desde el último
## punto de control o salir al menú principal.
## Lo abre y lo cierra el HUD; este script solo dibuja el menú y avisa qué botón se presionó.

signal continuar_presionado
signal reintentar_presionado
signal salir_presionado
signal guardar_presionado

var _continuar: Button
var _guardar: Button
var _reintentar: Button
var _salir: Button
var _mensaje: Label
var _panel: PanelContainer
var _ayuda: PanelComoJugar
var _boton_ayuda: Button


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var fondo := ColorRect.new()
	fondo.color = Color(0.0, 0.0, 0.0, 0.6)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", EstiloUI.panel(3, 24))
	centro.add_child(_panel)
	var columna := VBoxContainer.new()
	columna.custom_minimum_size = Vector2(420, 0)
	columna.add_theme_constant_override("separation", 12)
	_panel.add_child(columna)
	var titulo := EstiloUI.etiqueta("PAUSA", 40, EstiloUI.NOMBRE)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(titulo)
	_continuar = _boton("Continuar", continuar_presionado)
	_guardar = _boton("Guardar partida", guardar_presionado)
	_reintentar = _boton("Reintentar", reintentar_presionado)
	_boton_ayuda = EstiloUI.boton("Cómo jugar")
	_boton_ayuda.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boton_ayuda.pressed.connect(_abrir_ayuda)
	_salir = _boton("Salir al menú", salir_presionado)
	for b in [_continuar, _guardar, _reintentar, _boton_ayuda, _salir]:
		columna.add_child(b)
	_mensaje = EstiloUI.etiqueta("", 16, EstiloUI.NOMBRE)
	_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(_mensaje)
	var ayuda := EstiloUI.etiqueta("[Esc] Continuar", 14, EstiloUI.TENUE)
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(ayuda)
	_ayuda = PanelComoJugar.new()
	_ayuda.visible = false
	_ayuda.cerrado.connect(_al_cerrar_ayuda)
	centro.add_child(_ayuda)


func mostrar() -> void:
	if GameState.hay_punto_control():
		_reintentar.text = "Reintentar desde el punto de control"
	else:
		_reintentar.text = "Reintentar desde el inicio"
	_mensaje.text = ""
	_ayuda.visible = false
	_panel.visible = true
	visible = true
	_continuar.grab_focus()


func ocultar() -> void:
	visible = false


func ayuda_abierta() -> bool:
	return _ayuda.visible


func cerrar_ayuda() -> void:
	_ayuda.cerrar()


func _abrir_ayuda() -> void:
	_panel.visible = false
	_ayuda.abrir()


func _al_cerrar_ayuda() -> void:
	_panel.visible = true
	_boton_ayuda.grab_focus()


## Muestra un aviso corto debajo de los botones, por ejemplo "Partida guardada."
func mostrar_mensaje(texto: String) -> void:
	_mensaje.text = texto


func _boton(texto: String, senal: Signal) -> Button:
	var b := EstiloUI.boton(texto)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.pressed.connect(senal.emit)
	return b
