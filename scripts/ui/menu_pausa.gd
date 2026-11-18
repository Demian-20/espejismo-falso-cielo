class_name MenuPausa
extends CanvasLayer
## Menú de pausa (Esc o P): continuar, reintentar desde el último punto de control o salir.
## Lo abre y lo cierra el HUD; este script solo dibuja el menú y avisa qué botón se presionó.

signal continuar_presionado
signal reintentar_presionado
signal salir_presionado

var _continuar: Button
var _reintentar: Button
var _salir: Button


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
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", EstiloUI.panel(3, 24))
	centro.add_child(panel)
	var columna := VBoxContainer.new()
	columna.custom_minimum_size = Vector2(420, 0)
	columna.add_theme_constant_override("separation", 12)
	panel.add_child(columna)
	var titulo := EstiloUI.etiqueta("PAUSA", 40, EstiloUI.NOMBRE)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(titulo)
	_continuar = _boton("Continuar", continuar_presionado)
	_reintentar = _boton("Reintentar", reintentar_presionado)
	_salir = _boton("Salir", salir_presionado)
	for b in [_continuar, _reintentar, _salir]:
		columna.add_child(b)
	var ayuda := EstiloUI.etiqueta("[Esc] Continuar", 14, EstiloUI.TENUE)
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(ayuda)


func mostrar() -> void:
	if GameState.hay_punto_control():
		_reintentar.text = "Reintentar desde el punto de control"
	else:
		_reintentar.text = "Reintentar desde el inicio"
	visible = true
	_continuar.grab_focus()


func ocultar() -> void:
	visible = false


func _boton(texto: String, senal: Signal) -> Button:
	var b := EstiloUI.boton(texto)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.pressed.connect(senal.emit)
	return b
