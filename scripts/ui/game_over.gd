class_name PantallaGameOver
extends CanvasLayer
## Pantalla de Game Over: aparece con la señal `game_over` de GameState, muestra el
## puntaje final y las evidencias, y permite reintentar desde el último punto de control.

## Se emite al presionar Reintentar; el HUD regresa al punto de control y recarga el nivel.
signal reintentar_presionado
## Se emite al presionar Salir al menú.
signal salir_presionado

## Segundos de espera antes de mostrarse, para que se alcance a ver la animación de muerte.
const RETRASO := 1.2
const MENSAJE_POR_DEFECTO := "Nadie acudió a tu llamado en la oscuridad del callejón."

## Mensaje de la siguiente pantalla de Game Over. Se puede cambiar justo antes de quitar
## la última vida, por ejemplo: HUD.game_over.mensaje = "El narco te alcanzó en el callejón."
var mensaje: String = MENSAJE_POR_DEFECTO

var _fondo: ColorRect
var _contenido: VBoxContainer
var _mensaje: Label
var _puntaje: Label
var _evidencias: Label
var _reintentar: Button
var _salir: Button


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_fondo = ColorRect.new()
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	_contenido = VBoxContainer.new()
	_contenido.custom_minimum_size = Vector2(560, 0)
	_contenido.add_theme_constant_override("separation", 14)
	centro.add_child(_contenido)
	var titulo := EstiloUI.etiqueta("FIN DEL JUEGO", 52, EstiloUI.ROJO)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_contenido.add_child(titulo)
	_mensaje = _etiqueta_centrada(22, EstiloUI.TEXTO)
	_contenido.add_child(_mensaje)
	_contenido.add_child(HSeparator.new())
	_puntaje = _etiqueta_centrada(24, EstiloUI.NOMBRE)
	_contenido.add_child(_puntaje)
	_evidencias = _etiqueta_centrada(18, EstiloUI.TENUE)
	_contenido.add_child(_evidencias)
	_reintentar = EstiloUI.boton("Reintentar")
	_reintentar.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reintentar.pressed.connect(_al_reintentar)
	_contenido.add_child(_reintentar)
	_salir = EstiloUI.boton("Salir al menú")
	_salir.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_salir.pressed.connect(_al_salir)
	_contenido.add_child(_salir)
	GameState.game_over.connect(_al_game_over)


## Muestra la pantalla con el puntaje y las evidencias actuales, y pausa el juego.
func mostrar() -> void:
	_mensaje.text = mensaje
	_puntaje.text = "Puntaje final: %d" % GameState.puntaje
	if GameState.evidencias.is_empty():
		_evidencias.text = "Evidencias: ninguna"
	else:
		_evidencias.text = "Evidencias: " + ", ".join(GameState.evidencias)
	visible = true
	get_tree().paused = true
	_fondo.color = Color(0.45, 0.0, 0.0, 0.0)
	_contenido.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_fondo, "color", Color(0.04, 0.0, 0.0, 0.9), 0.8)
	tween.parallel().tween_property(_contenido, "modulate:a", 1.0, 0.8)
	_reintentar.grab_focus()


func esta_visible() -> bool:
	return visible


func _al_game_over() -> void:
	await get_tree().create_timer(RETRASO).timeout
	mostrar()


func _al_reintentar() -> void:
	visible = false
	mensaje = MENSAJE_POR_DEFECTO
	reintentar_presionado.emit()


func _al_salir() -> void:
	salir_presionado.emit()


func _etiqueta_centrada(tamano: int, color: Color) -> Label:
	var l := EstiloUI.etiqueta("", tamano, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
