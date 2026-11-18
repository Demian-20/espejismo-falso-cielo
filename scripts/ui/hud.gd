extends CanvasLayer
## Interfaz del juego (autoload "HUD"): caja de diálogo, marcador, inventario,
## aviso de interacción e indicador de tensión.
##
## Ejemplos desde otros scripts:
##   await HUD.dialogo([HUD.linea("Doña Carmen", "Buenas tardes, joven.", "res://assets/retratos/dona_carmen.png")])
##   var opcion := await HUD.preguntar(HUD.linea("Don Chente", "¿No te sobrarán veinte pesitos?"), ["Darle los $20", "No darle nada"])
##   HUD.mostrar_aviso("[E] Hablar")

## true mientras hay un diálogo o el inventario abiertos; el jugador no se puede mover.
signal bloqueo_cambio(bloqueado: bool)
signal dialogo_iniciado
signal dialogo_terminado

var caja: CajaDialogo
var marcador: Marcador
var inventario: PanelInventario
var _aviso: PanelContainer
var _texto_aviso: Label
var _tension: VBoxContainer
var _barra_tension: ProgressBar
var _bloqueos: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	marcador = Marcador.new()
	add_child(marcador)
	inventario = PanelInventario.new()
	add_child(inventario)
	caja = CajaDialogo.new()
	add_child(caja)
	_crear_aviso()
	_crear_tension()


## Arma una línea de diálogo. `retrato` puede ser una Texture2D o la ruta de la imagen.
func linea(nombre: String, texto: String, retrato: Variant = null) -> Dictionary:
	return {"nombre": nombre, "texto": texto, "retrato": retrato}


## Muestra varias líneas seguidas. Usar con await: termina cuando el jugador lee la última.
func dialogo(lineas: Array) -> void:
	_bloquear(true)
	dialogo_iniciado.emit()
	await caja.reproducir(lineas)
	dialogo_terminado.emit()
	_bloquear(false)


## Muestra una línea con opciones. Usar con await: regresa el índice de la opción elegida.
func preguntar(linea_pregunta: Dictionary, opciones: Array) -> int:
	_bloquear(true)
	dialogo_iniciado.emit()
	var indice: int = await caja.preguntar(linea_pregunta, opciones)
	dialogo_terminado.emit()
	_bloquear(false)
	return indice


func esta_en_dialogo() -> bool:
	return caja.visible


## Muestra un aviso pequeño sobre la caja de diálogo, por ejemplo "[E] Hablar".
func mostrar_aviso(texto: String) -> void:
	_texto_aviso.text = texto
	_aviso.visible = true


func ocultar_aviso() -> void:
	_aviso.visible = false


## Muestra la barra de tensión (0.0 a 1.0), por ejemplo durante la persecución.
func mostrar_tension(valor: float) -> void:
	_barra_tension.value = clampf(valor, 0.0, 1.0) * 100.0
	_tension.visible = true


func ocultar_tension() -> void:
	_tension.visible = false


## Oculta o muestra el marcador (por ejemplo, en las pantallas de apertura).
func mostrar_marcador(mostrar: bool) -> void:
	marcador.visible = mostrar


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventario") and not caja.visible:
		get_viewport().set_input_as_handled()
		if inventario.visible:
			inventario.cerrar()
			_bloquear(false)
		else:
			inventario.abrir()
			_bloquear(true)
	elif event.is_action_pressed("ui_cancel") and inventario.visible:
		get_viewport().set_input_as_handled()
		inventario.cerrar()
		_bloquear(false)


func _bloquear(activar: bool) -> void:
	var antes := _bloqueos > 0
	_bloqueos = maxi(_bloqueos + (1 if activar else -1), 0)
	if (_bloqueos > 0) != antes:
		bloqueo_cambio.emit(_bloqueos > 0)


func _crear_aviso() -> void:
	_aviso = PanelContainer.new()
	_aviso.visible = false
	_aviso.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_aviso.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_aviso.offset_top = -280
	_aviso.offset_bottom = -244
	_aviso.add_theme_stylebox_override("panel", EstiloUI.panel(2, 8))
	_texto_aviso = EstiloUI.etiqueta("", 18)
	_aviso.add_child(_texto_aviso)
	add_child(_aviso)


func _crear_tension() -> void:
	_tension = VBoxContainer.new()
	_tension.visible = false
	_tension.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_tension.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_tension.offset_top = 18
	_tension.custom_minimum_size = Vector2(260, 0)
	var titulo := EstiloUI.etiqueta("ALERTA", 16, EstiloUI.ROJO)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tension.add_child(titulo)
	_barra_tension = ProgressBar.new()
	_barra_tension.show_percentage = false
	_barra_tension.custom_minimum_size = Vector2(260, 14)
	var fondo := EstiloUI.panel(2, 0)
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = EstiloUI.ROJO
	_barra_tension.add_theme_stylebox_override("background", fondo)
	_barra_tension.add_theme_stylebox_override("fill", relleno)
	_tension.add_child(_barra_tension)
	add_child(_tension)
