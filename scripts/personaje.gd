class_name Personaje
extends CharacterBody2D
## Clase base de todos los personajes del mapa: el jugador, los NPCs y los enemigos.
## Maneja el movimiento y las animaciones de 64x64 (idle_ y walk_ en tres direcciones).

@export var nombre_mostrado: String = ""
@export var velocidad_base: float = 160.0

var velocidad: float
var direccion_mirada: Vector2 = Vector2.DOWN
var ultima_direccion: String = "abajo"

@onready var animacion: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	velocidad = velocidad_base


## Mueve al personaje en la dirección dada y actualiza su animación.
func mover(direccion: Vector2) -> void:
	velocity = direccion * velocidad
	move_and_slide()
	actualizar_animacion(direccion)


## Elige la animación según la dirección; la vista de lado se espeja hacia la izquierda.
func actualizar_animacion(direccion: Vector2) -> void:
	if direccion == Vector2.ZERO:
		animacion.play("idle_" + ultima_direccion)
		return
	direccion_mirada = direccion
	if direccion.x != 0.0:
		ultima_direccion = "lado"
		animacion.flip_h = direccion.x < 0.0
	elif direccion.y < 0.0:
		ultima_direccion = "arriba"
		animacion.flip_h = false
	else:
		ultima_direccion = "abajo"
		animacion.flip_h = false
	animacion.play("walk_" + ultima_direccion)
