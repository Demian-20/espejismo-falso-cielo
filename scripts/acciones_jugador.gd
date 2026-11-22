class_name AccionesJugador
extends Node
## Acciones del jugador (issue #8): interactuar con E y correr con Shift.
## Vive en un nodo hijo de Jugador para trabajarlo sin editar jugador.gd.
##
## - Interactuar: un detector alrededor de Mateo encuentra las zonas Interactuable
##   cercanas, muestra "[E] ..." de la más cercana y al presionar E llama a su interactuar().
## - Correr: solo funciona en modo huida (la persecución del callejón). Con Shift la
##   velocidad sube a 210 y la animación se acelera a 1.8, como pide el guion.

## Se emite al empezar o dejar de correr.
signal corriendo_cambio(corriendo: bool)

const VELOCIDAD_HUIDA: float = 210.0
const ANIMACION_HUIDA: float = 1.8
## Radio del detector de Mateo; se suma al radio de cada zona Interactuable.
const RADIO_DETECTOR: float = 20.0

## true durante la persecución: Shift hace correr a Mateo.
var modo_huida: bool = false
var corriendo: bool = false

var _detector: Area2D
var _cercanos: Array[Interactuable] = []
var _objetivo: Interactuable = null
var _aviso_actual: String = ""
var _ocupado: bool = false

@onready var jugador: Jugador = get_parent() as Jugador


func _ready() -> void:
	_detector = Area2D.new()
	_detector.name = "DetectorInteraccion"
	_detector.collision_layer = 0
	_detector.collision_mask = Interactuable.CAPA
	_detector.monitorable = false
	_detector.position = Vector2(0, -6)
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = RADIO_DETECTOR
	forma.shape = circulo
	_detector.add_child(forma)
	_detector.area_entered.connect(_al_entrar_zona)
	_detector.area_exited.connect(_al_salir_zona)
	jugador.add_child.call_deferred(_detector)


## Activa o desactiva el modo huida. Al desactivarlo Mateo vuelve a caminar normal.
func activar_modo_huida(activo: bool) -> void:
	modo_huida = activo
	if not activo:
		_cambiar_corriendo(false)


## La zona que se usaría al presionar E (o null si no hay ninguna cerca).
func objetivo_actual() -> Interactuable:
	return _objetivo


func _physics_process(_delta: float) -> void:
	_cambiar_corriendo(modo_huida and jugador.puede_moverse and Input.is_action_pressed("correr"))
	_objetivo = _buscar_objetivo()
	_actualizar_aviso()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interactuar") or not _puede_interactuar():
		return
	if _objetivo == null:
		return
	get_viewport().set_input_as_handled()
	_interactuar_con(_objetivo)


func _interactuar_con(zona: Interactuable) -> void:
	_ocupado = true
	_actualizar_aviso()
	_mirar_hacia(zona.global_position)
	await zona.interactuar()
	_ocupado = false


func _puede_interactuar() -> bool:
	return not _ocupado and jugador.puede_moverse and not HUD.esta_en_dialogo() \
		and not HUD.esta_en_pausa()


func _buscar_objetivo() -> Interactuable:
	var mejor: Interactuable = null
	var mejor_distancia: float = INF
	for zona in _cercanos:
		if not is_instance_valid(zona) or not zona.activo:
			continue
		var distancia: float = zona.global_position.distance_squared_to(_detector.global_position)
		if distancia < mejor_distancia:
			mejor = zona
			mejor_distancia = distancia
	return mejor


## Muestra u oculta el aviso "[E] ..." solo cuando cambia, para no pisar otros avisos.
func _actualizar_aviso() -> void:
	var texto: String = ""
	if _objetivo != null and _puede_interactuar():
		texto = "[E] " + _objetivo.texto
	if texto == _aviso_actual:
		return
	_aviso_actual = texto
	if texto == "":
		HUD.ocultar_aviso()
	else:
		HUD.mostrar_aviso(texto)


func _cambiar_corriendo(activo: bool) -> void:
	if activo == corriendo:
		return
	corriendo = activo
	jugador.velocidad = VELOCIDAD_HUIDA if activo else jugador.velocidad_base
	jugador.animacion.speed_scale = ANIMACION_HUIDA if activo else 1.0
	corriendo_cambio.emit(activo)


## Voltea a Mateo hacia lo que está usando, sin moverlo.
func _mirar_hacia(punto: Vector2) -> void:
	var diferencia: Vector2 = punto - jugador.global_position
	if absf(diferencia.x) > absf(diferencia.y):
		jugador.ultima_direccion = "lado"
		jugador.animacion.flip_h = diferencia.x < 0.0
	elif diferencia.y < 0.0:
		jugador.ultima_direccion = "arriba"
		jugador.animacion.flip_h = false
	else:
		jugador.ultima_direccion = "abajo"
		jugador.animacion.flip_h = false
	jugador.animacion.play("idle_" + jugador.ultima_direccion)


func _al_entrar_zona(area: Area2D) -> void:
	if area is Interactuable and not _cercanos.has(area):
		_cercanos.append(area as Interactuable)


func _al_salir_zona(area: Area2D) -> void:
	if area is Interactuable:
		_cercanos.erase(area as Interactuable)
