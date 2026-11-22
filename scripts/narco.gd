class_name Narco
extends Personaje
## Narco del callejón (issue #7): persigue a Mateo esquivando los obstáculos con
## NavigationAgent2D y, al final, lo acorrala y le apunta con la pistola.
##
## La escena del callejón decide cuándo perseguir o acorralar; el narco solo avisa
## con señales cuando alcanza a Mateo o cuando ya lo tiene acorralado.

## Se emite cuando alcanza a Mateo durante la persecución.
signal mateo_alcanzado
## Se emite cuando llega frente a Mateo y le apunta. Aquí empieza el desenlace (#17).
signal mateo_acorralado
## Se emite cuando termina de acercarse con acercarse().
signal llego

enum Estado { QUIETO, ACERCANDO, PERSIGUIENDO, ACORRALANDO, APUNTANDO }

const VELOCIDAD_PERSECUCION: float = 170.0
const VELOCIDAD_CAMINAR: float = 110.0
## Distancia a la que cuenta como que alcanzó a Mateo.
const DISTANCIA_ALCANCE: float = 26.0
## Distancia a la que se detiene para apuntarle.
const DISTANCIA_APUNTAR: float = 80.0

var estado: Estado = Estado.QUIETO
var objetivo: Node2D = null
var _distancia_parada: float = 0.0

@onready var agente: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	super._ready()
	animacion.play("idle_lado")


## Camina hacia `jugador` y se detiene a `distancia` píxeles (emite `llego`).
func acercarse(jugador: Node2D, distancia: float) -> void:
	objetivo = jugador
	_distancia_parada = distancia
	velocidad = VELOCIDAD_CAMINAR
	estado = Estado.ACERCANDO


## Empieza la persecución a toda velocidad.
func perseguir(jugador: Node2D) -> void:
	objetivo = jugador
	velocidad = VELOCIDAD_PERSECUCION
	estado = Estado.PERSIGUIENDO


## Camina hasta Mateo, se detiene enfrente y le apunta (emite `mateo_acorralado`).
func acorralar(jugador: Node2D) -> void:
	objetivo = jugador
	_distancia_parada = DISTANCIA_APUNTAR
	velocidad = VELOCIDAD_CAMINAR
	estado = Estado.ACORRALANDO


## Se queda quieto donde está.
func detener() -> void:
	estado = Estado.QUIETO
	velocity = Vector2.ZERO
	actualizar_animacion(Vector2.ZERO)


## Voltea hacia un punto sin moverse.
func mirar_hacia(punto: Vector2) -> void:
	_voltear(_cardinal(punto - global_position))
	animacion.play("idle_" + ultima_direccion)


func _physics_process(_delta: float) -> void:
	if objetivo == null or estado == Estado.QUIETO or estado == Estado.APUNTANDO:
		return
	var distancia: float = global_position.distance_to(objetivo.global_position)
	match estado:
		Estado.PERSIGUIENDO:
			if distancia <= DISTANCIA_ALCANCE:
				detener()
				mateo_alcanzado.emit()
				return
		Estado.ACERCANDO:
			if distancia <= _distancia_parada:
				detener()
				mirar_hacia(objetivo.global_position)
				llego.emit()
				return
		Estado.ACORRALANDO:
			if distancia <= _distancia_parada:
				_apuntar()
				return
	_caminar_hacia(objetivo.global_position)


func _caminar_hacia(punto: Vector2) -> void:
	agente.target_position = punto
	var siguiente: Vector2 = agente.get_next_path_position()
	var direccion: Vector2 = global_position.direction_to(siguiente)
	velocity = direccion * velocidad
	move_and_slide()
	actualizar_animacion(_cardinal(direccion))


func _apuntar() -> void:
	estado = Estado.APUNTANDO
	velocity = Vector2.ZERO
	_voltear(_cardinal(objetivo.global_position - global_position))
	animacion.animation = "pistola_" + ultima_direccion
	animacion.stop()
	animacion.frame = 0
	mateo_acorralado.emit()


## Convierte una dirección cualquiera en arriba, abajo, izquierda o derecha.
func _cardinal(direccion: Vector2) -> Vector2:
	if direccion == Vector2.ZERO:
		return Vector2.ZERO
	if absf(direccion.x) > absf(direccion.y):
		return Vector2(signf(direccion.x), 0.0)
	return Vector2(0.0, signf(direccion.y))


func _voltear(direccion: Vector2) -> void:
	if direccion.x != 0.0:
		ultima_direccion = "lado"
		animacion.flip_h = direccion.x < 0.0
	elif direccion.y < 0.0:
		ultima_direccion = "arriba"
		animacion.flip_h = false
	elif direccion.y > 0.0:
		ultima_direccion = "abajo"
		animacion.flip_h = false
