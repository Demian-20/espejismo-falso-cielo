extends Node2D
## Callejón del prólogo (issue #7): el encuentro con el narco, la persecución y el
## acorralamiento frente a la reja (Fase 4 del guion).
##
## - La entrada está en la parte de arriba de la calle, junto a las obras. Solo se puede
##   usar de noche: el #9 tiene que cambiar GameState.etapa_prologo a NOCHE.
## - El callejón es una zona aparte (nodo Zona) a la derecha del mapa de la plaza.
## - Si el narco alcanza a Mateo, pierde una vida y la persecución vuelve a empezar.
##   Con 0 vidas aparece el Game Over.
## - Si Mateo llega a la reja, suma +300 y el narco lo acorrala con la pistola.
##   Ahí se emite `mateo_acorralado` para el desenlace (#17).

## Se emite cuando empieza la persecución.
signal persecucion_iniciada
## Se emite cuando el narco ya le está apuntando a Mateo frente a la reja (para el #17).
signal mateo_acorralado

enum Fase { AFUERA, ENTRANDO, ENCUENTRO, PERSECUCION, ACORRALADO }

const RETRATO_MATEO := "res://assets/retratos/mateo_asustado.png"
const RETRATO_NARCO := "res://assets/retratos/narco.png"
const VOZ_MATEO := 0.98
const VOZ_NARCO := 0.7
## Tamaño de la zona del callejón (el fondo mide 640 x 1700).
const TAMANO_ZONA := Vector2(640, 1700)
## Área donde se puede caminar dentro de la zona (entre los muros, la reja y la pared del fondo).
const AREA_LIBRE := Rect2(150, 200, 340, 1450)
## El narco se acerca a esta distancia durante el diálogo antes de arrancar.
const DISTANCIA_INICIAL := 140.0
## Segundos que tarda el narco en arrancar después del diálogo y después de alcanzarte.
const REACCION_NARCO := 0.5
const GRACIA_ALCANCE := 1.0
const MENSAJE_GAME_OVER := "El narco te alcanzó en el callejón."

var fase: Fase = Fase.AFUERA
var jugador: Jugador = null
var _inicio_persecucion_jugador: Vector2
var _inicio_persecucion_narco: Vector2
var _velo: ColorRect

@onready var entrada: Interactuable = $Entrada
@onready var zona: Node2D = $Zona
@onready var narco: Narco = $Zona/Narco
@onready var navegacion: NavigationRegion2D = $Zona/Navegacion
@onready var inicio_jugador: Marker2D = $Zona/InicioJugador
@onready var encuentro: Area2D = $Zona/Encuentro
@onready var final: Area2D = $Zona/Final


func _ready() -> void:
	entrada.receptor = self
	_actualizar_entrada(GameState.etapa_prologo)
	GameState.etapa_cambio.connect(_actualizar_entrada)
	encuentro.body_entered.connect(_al_entrar_encuentro)
	final.body_entered.connect(_al_llegar_final)
	narco.mateo_alcanzado.connect(_al_alcanzar)
	narco.mateo_acorralado.connect(_al_acorralar)
	narco.mirar_hacia(narco.global_position + Vector2.RIGHT)
	_crear_velo()
	_hornear_navegacion()


func _process(_delta: float) -> void:
	if fase == Fase.PERSECUCION and jugador != null:
		var distancia: float = jugador.global_position.distance_to(narco.global_position)
		HUD.mostrar_tension(1.0 - (distancia - Narco.DISTANCIA_ALCANCE) / 260.0)


## La llama la entrada al presionar E: Mateo entra al callejón.
func interactuar() -> void:
	if fase != Fase.AFUERA:
		return
	jugador = get_parent().get_node_or_null("Jugador") as Jugador
	if jugador == null:
		return
	fase = Fase.ENTRANDO
	entrada.activo = false
	jugador.puede_moverse = false
	await _fundido(1.0, 0.6)
	jugador.global_position = inicio_jugador.global_position
	_voltear_jugador("arriba")
	_limitar_camara(true)
	await get_tree().physics_frame
	await _fundido(0.0, 0.6)
	jugador.puede_moverse = true


func _actualizar_entrada(etapa: int) -> void:
	entrada.activo = fase == Fase.AFUERA and etapa >= GameState.Etapa.NOCHE


func _al_entrar_encuentro(cuerpo: Node2D) -> void:
	if cuerpo is Jugador and fase == Fase.ENTRANDO:
		fase = Fase.ENCUENTRO
		_encuentro()


## El narco descubre a Mateo, se le acerca y arranca la persecución.
func _encuentro() -> void:
	jugador.puede_moverse = false
	narco.mirar_hacia(jugador.global_position)
	await HUD.dialogo([
		HUD.linea("Narco", "¡Ey, tú! ¡¿Qué andas espiando aquí, morro?!", RETRATO_NARCO, VOZ_NARCO),
	])
	_voltear_jugador_hacia(narco.global_position)
	narco.acercarse(jugador, DISTANCIA_INICIAL)
	await HUD.dialogo([
		HUD.linea("Mateo", "¡¿Qué...?! Perdón, yo solo iba de paso—", RETRATO_MATEO, VOZ_MATEO),
		HUD.linea("Narco", "¡Ven pa' acá! ¡De este callejón no vas a salir a contar nada!", RETRATO_NARCO, VOZ_NARCO),
	])
	if fase != Fase.ENCUENTRO:
		return
	narco.detener()
	_inicio_persecucion_jugador = jugador.global_position
	_inicio_persecucion_narco = narco.global_position
	GameState.etapa_prologo = GameState.Etapa.PERSECUCION
	jugador.activar_modo_huida(true)
	jugador.puede_moverse = true
	fase = Fase.PERSECUCION
	persecucion_iniciada.emit()
	_aviso_temporal("¡Presiona [SHIFT / ESPACIO] para correr y esquiva los obstáculos!", 3.5)
	await get_tree().create_timer(REACCION_NARCO).timeout
	if fase == Fase.PERSECUCION:
		narco.perseguir(jugador)


## El narco alcanzó a Mateo: pierde una vida y la persecución vuelve a empezar.
func _al_alcanzar() -> void:
	if fase != Fase.PERSECUCION:
		return
	fase = Fase.ENCUENTRO
	jugador.puede_moverse = false
	jugador.animacion.play("dano_" + jugador.ultima_direccion)
	if GameState.vidas <= 1:
		HUD.game_over.mensaje = MENSAJE_GAME_OVER
	var vidas_restantes: int = GameState.perder_vida()
	if vidas_restantes <= 0:
		jugador.activar_modo_huida(false)
		HUD.ocultar_tension()
		HUD.ocultar_aviso()
		jugador.animacion.play("muerte")
		return
	await get_tree().create_timer(0.5).timeout
	await _fundido(1.0, 0.35)
	jugador.global_position = _inicio_persecucion_jugador
	narco.global_position = _inicio_persecucion_narco
	narco.detener()
	narco.mirar_hacia(jugador.global_position)
	_voltear_jugador("arriba")
	await get_tree().physics_frame
	await _fundido(0.0, 0.35)
	fase = Fase.PERSECUCION
	jugador.puede_moverse = true
	_aviso_temporal("¡Te alcanzó! Te quedan %d vidas. ¡Corre!" % vidas_restantes, 2.0)
	await get_tree().create_timer(GRACIA_ALCANCE).timeout
	if fase == Fase.PERSECUCION:
		narco.perseguir(jugador)


## Mateo llegó a la reja: +300 puntos y el narco lo acorrala.
func _al_llegar_final(cuerpo: Node2D) -> void:
	if not cuerpo is Jugador or fase != Fase.PERSECUCION:
		return
	fase = Fase.ACORRALADO
	GameState.agregar_puntos(GameState.PUNTOS_ESCAPAR_NARCO)
	jugador.activar_modo_huida(false)
	HUD.ocultar_tension()
	HUD.ocultar_aviso()
	_voltear_jugador("arriba")
	narco.acorralar(jugador)
	await HUD.dialogo([
		HUD.linea("Mateo", "¡No, no, no...! ¡Está cerrada con candado!", RETRATO_MATEO, VOZ_MATEO),
	])
	jugador.puede_moverse = false
	_voltear_jugador_hacia(narco.global_position)


func _al_acorralar() -> void:
	if jugador != null:
		jugador.puede_moverse = false
		_voltear_jugador_hacia(narco.global_position)
	mateo_acorralado.emit()


## Arma la malla de navegación del narco con el área libre y los obstáculos.
func _hornear_navegacion() -> void:
	var poligono := NavigationPolygon.new()
	poligono.agent_radius = 12.0
	poligono.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	poligono.parsed_collision_mask = 1
	var r := AREA_LIBRE
	poligono.add_outline(PackedVector2Array([
		r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y),
	]))
	navegacion.navigation_polygon = poligono
	navegacion.bake_navigation_polygon(false)


## Dentro del callejón la cámara no se sale de la zona.
func _limitar_camara(activo: bool) -> void:
	var camara := jugador.get_node_or_null("Camera2D") as Camera2D
	if camara == null:
		return
	if activo:
		camara.limit_left = int(zona.global_position.x)
		camara.limit_top = int(zona.global_position.y)
		camara.limit_right = int(zona.global_position.x + TAMANO_ZONA.x)
		camara.limit_bottom = int(zona.global_position.y + TAMANO_ZONA.y)
	else:
		camara.limit_left = -10000000
		camara.limit_top = -10000000
		camara.limit_right = 10000000
		camara.limit_bottom = 10000000
	camara.reset_smoothing()


func _voltear_jugador(direccion: String) -> void:
	jugador.ultima_direccion = direccion
	jugador.animacion.flip_h = false
	jugador.animacion.play("idle_" + direccion)


func _voltear_jugador_hacia(punto: Vector2) -> void:
	var diferencia: Vector2 = punto - jugador.global_position
	if absf(diferencia.x) > absf(diferencia.y):
		_voltear_jugador("lado")
		jugador.animacion.flip_h = diferencia.x < 0.0
	else:
		_voltear_jugador("arriba" if diferencia.y < 0.0 else "abajo")


func _aviso_temporal(texto: String, segundos: float) -> void:
	HUD.mostrar_aviso(texto)
	await get_tree().create_timer(segundos).timeout
	if HUD._texto_aviso.text == texto:
		HUD.ocultar_aviso()


func _crear_velo() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 10
	add_child(capa)
	_velo = ColorRect.new()
	_velo.color = Color(0, 0, 0, 0)
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(_velo)


func _fundido(alfa: float, segundos: float) -> void:
	var tween := create_tween()
	tween.tween_property(_velo, "color:a", alfa, segundos)
	await tween.finished
