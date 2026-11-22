class_name NPCAmbiental
extends NPC
## NPC de ambiente de la plaza (issue #16): el Oficial Cárdenas y los civiles.
##
## Dice sus líneas al hablarle con E (+50 puntos la primera vez). Si tiene ruta, camina
## entre los puntos sin diagonales, espera un momento en cada uno y se detiene
## mientras platica con Mateo. Sin ruta se queda fijo en su lugar.

## Retrato para la caja de diálogo.
@export_file("*.png") var retrato: String = ""
## Lo que dice al hablarle; cada texto es una línea del diálogo.
@export_multiline var lineas: PackedStringArray = PackedStringArray()
## Tono de su voz en el diálogo (más bajo = más grave).
@export var voz: float = 1.0
## Puntos de la ruta, relativos a su posición inicial. Vacía = se queda fijo.
@export var ruta: PackedVector2Array = PackedVector2Array()
## Segundos que espera en cada punto de la ruta.
@export var pausa: float = 1.5

var hablando: bool = false

var _inicio: Vector2
var _indice: int = 0
var _espera: float = 0.0
var _atorado: float = 0.0


func _ready() -> void:
	super._ready()
	_inicio = global_position
	_espera = pausa


func _physics_process(delta: float) -> void:
	if hablando or ruta.is_empty():
		return
	if _espera > 0.0:
		_espera -= delta
		mover(Vector2.ZERO)
		return
	var diferencia: Vector2 = _inicio + ruta[_indice] - global_position
	if diferencia.length() < 3.0:
		_siguiente_punto()
		return
	var direccion: Vector2
	if absf(diferencia.x) > 2.0:
		direccion = Vector2(signf(diferencia.x), 0.0)
	else:
		direccion = Vector2(0.0, signf(diferencia.y))
	var antes: Vector2 = global_position
	mover(direccion)
	# Si algo le estorba (por ejemplo, Mateo) por más de un segundo, sigue al siguiente punto.
	if global_position.distance_to(antes) < 0.1:
		_atorado += delta
		if _atorado > 1.0:
			_siguiente_punto()
	else:
		_atorado = 0.0


## Se detiene, voltea hacia Mateo y dice sus líneas.
func interactuar() -> void:
	hablando = true
	mover(Vector2.ZERO)
	var jugador := get_tree().current_scene.get_node_or_null("Jugador") as Node2D
	if jugador != null:
		_mirar_hacia(jugador.global_position)
	GameState.hablar_con_npc(id_npc)
	var foto: Variant = retrato if retrato != "" else null
	var dialogo: Array = []
	for texto in lineas:
		dialogo.append(HUD.linea(nombre_mostrado, texto, foto, voz))
	if not dialogo.is_empty():
		await HUD.dialogo(dialogo)
	hablando = false


func _siguiente_punto() -> void:
	_indice = (_indice + 1) % ruta.size()
	_espera = pausa
	_atorado = 0.0


func _mirar_hacia(punto: Vector2) -> void:
	var diferencia: Vector2 = punto - global_position
	if absf(diferencia.x) > absf(diferencia.y):
		ultima_direccion = "lado"
		animacion.flip_h = diferencia.x < 0.0
	elif diferencia.y < 0.0:
		ultima_direccion = "arriba"
		animacion.flip_h = false
	else:
		ultima_direccion = "abajo"
		animacion.flip_h = false
	animacion.play("idle_" + ultima_direccion)
