class_name PanelInventario
extends PanelContainer
## Panel lateral con las evidencias recolectadas. Al seleccionar una se muestra su descripción.

## Descripción de cada evidencia. Agreguen aquí las nuevas.
const DESCRIPCIONES := {
	"Ficha de Búsqueda de Doña Carmen": "Volante con la foto del hijo de Doña Carmen, desaparecido en Hermosillo hace unos meses. Ella reparte estas fichas en la Plaza Zaragoza.",
}

var _lista: ItemList
var _descripcion: Label
var _dinero: Label


func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	offset_left = -400
	offset_right = -16
	offset_top = 16
	offset_bottom = -240
	add_theme_stylebox_override("panel", EstiloUI.panel())
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	add_child(columna)
	columna.add_child(EstiloUI.etiqueta("Evidencias", 22, EstiloUI.NOMBRE))
	_lista = ItemList.new()
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista.add_theme_font_size_override("font_size", 16)
	_lista.add_theme_color_override("font_color", EstiloUI.TEXTO)
	_lista.add_theme_color_override("font_selected_color", EstiloUI.NOMBRE)
	var fondo_lista := EstiloUI.panel(1, 6)
	fondo_lista.bg_color = EstiloUI.FONDO_CLARO
	_lista.add_theme_stylebox_override("panel", fondo_lista)
	_lista.item_selected.connect(_al_seleccionar)
	columna.add_child(_lista)
	_descripcion = EstiloUI.etiqueta("", 16, EstiloUI.TEXTO)
	_descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_descripcion.custom_minimum_size = Vector2(0, 90)
	columna.add_child(_descripcion)
	_dinero = EstiloUI.etiqueta("", 17, EstiloUI.TENUE)
	columna.add_child(_dinero)
	columna.add_child(EstiloUI.etiqueta("[Tab] Cerrar", 14, EstiloUI.TENUE))
	GameState.evidencias_cambio.connect(_al_cambiar_evidencias)


func abrir() -> void:
	_actualizar()
	visible = true
	if _lista.item_count > 0:
		_lista.select(0)
		_al_seleccionar(0)
		_lista.grab_focus()


func cerrar() -> void:
	visible = false
	_lista.release_focus()


func _al_cambiar_evidencias(_evidencias: Array[String]) -> void:
	_actualizar()


func _actualizar() -> void:
	_lista.clear()
	for nombre in GameState.evidencias:
		_lista.add_item(nombre)
	_dinero.text = "Dinero: $%d" % GameState.dinero
	if _lista.item_count == 0:
		_descripcion.text = "Todavía no tienes evidencias."


func _al_seleccionar(indice: int) -> void:
	var nombre := _lista.get_item_text(indice)
	_descripcion.text = DESCRIPCIONES.get(nombre, "Sin descripción.")
