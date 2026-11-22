class_name PantallaResultados
extends CanvasLayer
## Pantalla de resultados al terminar el prólogo (#30): "Fin del prólogo", puntaje con
## desglose, vidas, evidencias, la decisión con Don Chente y un rango.

signal menu_presionado

## Nombres de las pistas opcionales de la plaza (nivel/objetos.tscn).
const PISTAS: Array[String] = ["Volante del callejón", "Casquillo de bala", "Nota arrugada"]
const EVIDENCIA_CARMEN := "Ficha de Búsqueda de Doña Carmen"

var _contenido: VBoxContainer
var _filas: VBoxContainer
var _total: Label
var _rango: Label
var _resumen: Label
var _menu: Button


func _ready() -> void:
	layer = 19
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var fondo := ColorRect.new()
	fondo.color = Color(0.02, 0.01, 0.03, 0.96)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	_contenido = VBoxContainer.new()
	_contenido.custom_minimum_size = Vector2(620, 0)
	_contenido.add_theme_constant_override("separation", 10)
	centro.add_child(_contenido)
	var titulo := EstiloUI.etiqueta("FIN DEL PRÓLOGO", 46, EstiloUI.NOMBRE)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_contenido.add_child(titulo)
	var sub := EstiloUI.etiqueta("Continuará...", 20, EstiloUI.TENUE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_contenido.add_child(sub)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", EstiloUI.panel(2, 18))
	_contenido.add_child(panel)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 6)
	panel.add_child(columna)
	_filas = VBoxContainer.new()
	_filas.add_theme_constant_override("separation", 4)
	columna.add_child(_filas)
	columna.add_child(HSeparator.new())
	_total = EstiloUI.etiqueta("", 28, EstiloUI.NOMBRE)
	_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(_total)
	_rango = EstiloUI.etiqueta("", 20, EstiloUI.TEXTO)
	_rango.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(_rango)
	_resumen = EstiloUI.etiqueta("", 16, EstiloUI.TENUE)
	_resumen.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_resumen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_contenido.add_child(_resumen)
	_menu = EstiloUI.boton("Volver al menú")
	_menu.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu.pressed.connect(menu_presionado.emit)
	_contenido.add_child(_menu)


## Arma el desglose con el estado actual, pausa el juego y aparece con un fundido.
func mostrar() -> void:
	for fila in _filas.get_children():
		fila.queue_free()
	var npcs := GameState.npcs_hablados()
	var pistas := 0
	for p in PISTAS:
		if GameState.tiene_evidencia(p):
			pistas += 1
	_fila("Personas con las que hablaste (%d de %d)" % [npcs, GameState.TOTAL_NPCS], npcs * GameState.PUNTOS_HABLAR_NPC)
	_fila("Ficha de búsqueda de Doña Carmen", GameState.PUNTOS_FICHA_CARMEN if GameState.tiene_evidencia(EVIDENCIA_CARMEN) else 0)
	_fila("Ayudar a Don Chente con los $20", GameState.PUNTOS_AYUDAR_CHENTE if GameState.ayudo_a_chente else 0)
	_fila("Pistas encontradas (%d de %d)" % [pistas, GameState.TOTAL_PISTAS], pistas * GameState.PUNTOS_PISTA)
	_fila("Escapar del narco en el callejón", GameState.PUNTOS_ESCAPAR_NARCO)
	_total.text = "Puntaje final: %d" % GameState.puntaje
	_rango.text = "Rango: " + rango(GameState.puntaje)
	var decision := "Le diste tus últimos $20 a Don Chente." if GameState.ayudo_a_chente else "No le diste los $20 a Don Chente."
	_resumen.text = "%s  Vidas: %d de %d.  Evidencias: %d." % [decision, GameState.vidas, GameState.VIDAS_INICIALES, GameState.evidencias.size()]
	visible = true
	get_tree().paused = true
	_contenido.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_contenido, "modulate:a", 1.0, 1.0)
	_menu.grab_focus()


## Puntaje máximo del prólogo, sumando todo lo que se puede conseguir.
static func puntaje_maximo() -> int:
	return GameState.TOTAL_NPCS * GameState.PUNTOS_HABLAR_NPC + GameState.PUNTOS_FICHA_CARMEN \
		+ GameState.PUNTOS_AYUDAR_CHENTE + GameState.TOTAL_PISTAS * GameState.PUNTOS_PISTA \
		+ GameState.PUNTOS_ESCAPAR_NARCO


static func rango(puntaje: int) -> String:
	var parte := float(puntaje) / float(puntaje_maximo())
	if parte >= 0.85:
		return "Buscador de la verdad"
	if parte >= 0.6:
		return "Investigador"
	return "Testigo"


func _fila(texto: String, puntos: int) -> void:
	var fila := HBoxContainer.new()
	var nombre := EstiloUI.etiqueta(texto, 18, EstiloUI.TEXTO)
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(nombre)
	var valor := EstiloUI.etiqueta("+%d" % puntos, 18, EstiloUI.NOMBRE if puntos > 0 else EstiloUI.TENUE)
	fila.add_child(valor)
	_filas.add_child(fila)
