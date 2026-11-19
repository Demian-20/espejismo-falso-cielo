class_name Marcador
extends PanelContainer
## Marcador de la esquina superior: vidas (corazones), dinero, puntaje y evidencias.
## Se actualiza solo con las señales de GameState.

const DIBUJO_CORAZON: Array[String] = [
	".##.##.",
	"#rr#rr#",
	"#rrrrr#",
	"#rrrrr#",
	".#rrr#.",
	"..#r#..",
	"...#...",
]

var _corazones: HBoxContainer
var _dinero: Label
var _puntaje: Label
var _evidencias: Label
var _lleno: ImageTexture
var _vacio: ImageTexture


func _ready() -> void:
	position = Vector2(16, 16)
	add_theme_stylebox_override("panel", EstiloUI.panel(2, 10))
	_lleno = EstiloUI.textura_pixeles(DIBUJO_CORAZON, {"#": Color(0.15, 0.04, 0.04), "r": EstiloUI.ROJO})
	_vacio = EstiloUI.textura_pixeles(DIBUJO_CORAZON, {"#": Color(0.15, 0.04, 0.04), "r": Color(0.3, 0.24, 0.2)})
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 18)
	add_child(fila)
	_corazones = HBoxContainer.new()
	_corazones.add_theme_constant_override("separation", 4)
	fila.add_child(_corazones)
	for i in GameState.VIDAS_INICIALES:
		var c := TextureRect.new()
		c.custom_minimum_size = Vector2(21, 21)
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_corazones.add_child(c)
	_dinero = EstiloUI.etiqueta("", 18)
	_puntaje = EstiloUI.etiqueta("", 18, EstiloUI.NOMBRE)
	_evidencias = EstiloUI.etiqueta("", 18)
	fila.add_child(_dinero)
	fila.add_child(_puntaje)
	fila.add_child(_evidencias)
	GameState.vidas_cambio.connect(_al_cambiar_vidas)
	GameState.dinero_cambio.connect(_al_cambiar_dinero)
	GameState.puntaje_cambio.connect(_al_cambiar_puntaje)
	GameState.evidencias_cambio.connect(_al_cambiar_evidencias)
	_al_cambiar_vidas(GameState.vidas)
	_al_cambiar_dinero(GameState.dinero)
	_al_cambiar_puntaje(GameState.puntaje, 0)
	_al_cambiar_evidencias(GameState.evidencias)


func _al_cambiar_vidas(vidas: int) -> void:
	for i in _corazones.get_child_count():
		(_corazones.get_child(i) as TextureRect).texture = _lleno if i < vidas else _vacio


func _al_cambiar_dinero(dinero: int) -> void:
	_dinero.text = "$%d" % dinero


func _al_cambiar_puntaje(puntaje: int, _diferencia: int) -> void:
	_puntaje.text = "%d pts" % puntaje


func _al_cambiar_evidencias(evidencias: Array[String]) -> void:
	_evidencias.text = "Evidencias: %d" % evidencias.size()
