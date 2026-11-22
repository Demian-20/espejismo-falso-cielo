extends CanvasLayer
## Interfaz del juego (autoload "HUD"): caja de diálogo, marcador, inventario,
## aviso de interacción, indicador de tensión, menú de pausa y Game Over.
##
## Ejemplos desde otros scripts:
##   await HUD.dialogo([HUD.linea("Doña Carmen", "Buenas tardes, joven.", "res://assets/retratos/dona_carmen.png")])
##   var opcion := await HUD.preguntar(HUD.linea("Don Chente", "¿No te sobrarán veinte pesitos?"), ["Darle los $20", "No darle nada"])
##   HUD.mostrar_aviso("[E] Hablar")

## true mientras hay un diálogo o el inventario abiertos; el jugador no se puede mover.
signal bloqueo_cambio(bloqueado: bool)
signal dialogo_iniciado
signal dialogo_terminado

const ESCENA_MENU := "res://scenes/ui/menu_principal.tscn"

## false en el menú principal: no se abre la pausa ni el inventario y no hay marcador.
var en_juego: bool = true
var caja: CajaDialogo
var marcador: Marcador
var inventario: PanelInventario
var game_over: PantallaGameOver
var resultados: PantallaResultados
var menu_pausa: MenuPausa
var _aviso: PanelContainer
var _texto_aviso: Label
var _tension: VBoxContainer
var _notificacion: PanelContainer
var _texto_notificacion: Label
var _tween_notificacion: Tween
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
	_crear_notificacion()
	menu_pausa = preload("res://scenes/ui/menu_pausa.tscn").instantiate()
	menu_pausa.continuar_presionado.connect(continuar)
	menu_pausa.reintentar_presionado.connect(reintentar)
	menu_pausa.salir_presionado.connect(salir)
	menu_pausa.guardar_presionado.connect(guardar)
	add_child(menu_pausa)
	game_over = preload("res://scenes/ui/game_over.tscn").instantiate()
	game_over.reintentar_presionado.connect(reintentar)
	game_over.salir_presionado.connect(salir)
	add_child(game_over)
	resultados = PantallaResultados.new()
	resultados.menu_presionado.connect(salir)
	add_child(resultados)


## Arma una línea de diálogo. `retrato` puede ser una Texture2D o la ruta de la imagen.
func linea(nombre: String, texto: String, retrato: Variant = null, tono: float = 1.0) -> Dictionary:
	return {"nombre": nombre, "texto": texto, "retrato": retrato, "tono": tono}


## Muestra varias líneas seguidas. Usar con await: termina cuando el jugador lee la última.
func dialogo(lineas: Array) -> void:
	var marcador_estaba_visible := marcador.visible
	marcador.visible = false
	_bloquear(true)
	dialogo_iniciado.emit()
	await caja.reproducir(lineas)
	dialogo_terminado.emit()
	_bloquear(false)
	marcador.visible = marcador_estaba_visible


## Muestra una línea con opciones. Usar con await: regresa el índice de la opción elegida
## (o -1 si se canceló por un Game Over).
func preguntar(linea_pregunta: Dictionary, opciones: Array) -> int:
	var marcador_estaba_visible := marcador.visible
	marcador.visible = false
	_bloquear(true)
	dialogo_iniciado.emit()
	var indice: int = await caja.preguntar(linea_pregunta, opciones)
	dialogo_terminado.emit()
	_bloquear(false)
	marcador.visible = marcador_estaba_visible
	return indice


func esta_en_dialogo() -> bool:
	return caja.visible


## Muestra un aviso pequeño sobre la caja de diálogo, por ejemplo "[E] Hablar".
func mostrar_aviso(texto: String) -> void:
	_texto_aviso.text = texto
	_aviso.visible = true


func ocultar_aviso() -> void:
	_aviso.visible = false


## Muestra un mensaje corto arriba de la pantalla y lo oculta solo, por ejemplo
## "Evidencia obtenida: ... (+100)". No choca con el aviso de "[E]".
func notificar(texto: String, segundos: float = 3.0) -> void:
	_texto_notificacion.text = texto
	_notificacion.visible = true
	_notificacion.modulate.a = 1.0
	if _tween_notificacion != null and _tween_notificacion.is_valid():
		_tween_notificacion.kill()
	_tween_notificacion = create_tween()
	_tween_notificacion.tween_interval(segundos)
	_tween_notificacion.tween_property(_notificacion, "modulate:a", 0.0, 0.5)
	_tween_notificacion.tween_callback(func() -> void: _notificacion.visible = false)


## Muestra la barra de tensión (0.0 a 1.0), por ejemplo durante la persecución.
func mostrar_tension(valor: float) -> void:
	_barra_tension.value = clampf(valor, 0.0, 1.0) * 100.0
	_tension.visible = true


func ocultar_tension() -> void:
	_tension.visible = false


## Pausa el juego y abre el menú de pausa. No hace nada durante un diálogo o el Game Over.
func pausar() -> void:
	if caja.visible or game_over.visible or menu_pausa.visible:
		return
	if inventario.visible:
		inventario.cerrar()
		_bloquear(false)
	menu_pausa.mostrar()
	get_tree().paused = true


## Cierra el menú de pausa y sigue el juego.
func continuar() -> void:
	menu_pausa.ocultar()
	get_tree().paused = false


## Regresa al último punto de control (o reinicia la partida si no hay) y recarga el nivel.
## La usan el menú de pausa y el Game Over.
func reintentar() -> void:
	menu_pausa.ocultar()
	game_over.visible = false
	reiniciar_interfaz()
	get_tree().paused = false
	GameState.cargar_punto_control()
	get_tree().reload_current_scene()


## Regresa al menú principal (desde la pausa o el Game Over).
func salir() -> void:
	get_tree().paused = false
	salir_del_juego()
	get_tree().change_scene_to_file(ESCENA_MENU)


## Guarda la partida desde el menú de pausa y avisa si se pudo.
func guardar() -> void:
	var escena := get_tree().current_scene
	var jugador: Node2D = null
	if escena != null:
		jugador = escena.get_node_or_null("Jugador") as Node2D
	if not GameState.puede_guardar():
		menu_pausa.mostrar_mensaje("Solo se puede guardar de tarde, mientras exploras la plaza.")
		return
	if jugador == null:
		menu_pausa.mostrar_mensaje("Aquí no se puede guardar.")
		return
	if GameState.guardar_partida(escena.scene_file_path, jugador.global_position):
		menu_pausa.mostrar_mensaje("Partida guardada.")
	else:
		menu_pausa.mostrar_mensaje("No se pudo guardar la partida.")


## Muestra la pantalla de "Fin del prólogo" con el puntaje y el desglose.
func mostrar_resultados() -> void:
	reiniciar_interfaz()
	mostrar_marcador(false)
	resultados.mostrar()


## La llama el menú principal: cierra todo lo del juego y oculta el marcador.
func salir_del_juego() -> void:
	en_juego = false
	menu_pausa.ocultar()
	game_over.visible = false
	resultados.visible = false
	reiniciar_interfaz()
	mostrar_marcador(false)


## La llama el menú principal al empezar o cargar una partida.
func entrar_al_juego() -> void:
	en_juego = true


func esta_en_pausa() -> bool:
	return menu_pausa.visible


## Cierra el diálogo, el inventario, el aviso y la barra de tensión, y desbloquea al jugador.
## Se llama sola al reintentar.
func reiniciar_interfaz() -> void:
	caja.cancelar()
	inventario.cerrar()
	ocultar_aviso()
	ocultar_tension()
	_notificacion.visible = false
	if _bloqueos > 0:
		_bloqueos = 0
		bloqueo_cambio.emit(false)


## Oculta o muestra el marcador (por ejemplo, en las pantallas de apertura).
func mostrar_marcador(mostrar: bool) -> void:
	marcador.visible = mostrar


func _unhandled_input(event: InputEvent) -> void:
	if game_over.visible or resultados.visible or not en_juego:
		return
	var tecla_pausa := event.is_action_pressed("pausa") or event.is_action_pressed("ui_cancel")
	if menu_pausa.visible:
		if tecla_pausa:
			get_viewport().set_input_as_handled()
			if menu_pausa.ayuda_abierta():
				menu_pausa.cerrar_ayuda()
			else:
				continuar()
		return
	if inventario.visible:
		if tecla_pausa or event.is_action_pressed("inventario"):
			get_viewport().set_input_as_handled()
			inventario.cerrar()
			_bloquear(false)
		return
	if caja.visible:
		return
	if event.is_action_pressed("inventario"):
		get_viewport().set_input_as_handled()
		inventario.abrir()
		_bloquear(true)
	elif event.is_action_pressed("pausa"):
		get_viewport().set_input_as_handled()
		pausar()


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


func _crear_notificacion() -> void:
	_notificacion = PanelContainer.new()
	_notificacion.visible = false
	_notificacion.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_notificacion.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_notificacion.offset_top = 70
	_notificacion.add_theme_stylebox_override("panel", EstiloUI.panel(2, 10))
	_texto_notificacion = EstiloUI.etiqueta("", 18, EstiloUI.NOMBRE)
	_notificacion.add_child(_texto_notificacion)
	add_child(_notificacion)


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
