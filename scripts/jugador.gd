class_name Jugador
extends Personaje
## Mateo: lee las acciones del Input Map y se mueve en 4 direcciones.

## En false el jugador no se mueve (por ejemplo, mientras hay un diálogo abierto).
var puede_moverse: bool = true


func _ready() -> void:
	super._ready()
	HUD.bloqueo_cambio.connect(_al_cambiar_bloqueo)


func _physics_process(_delta: float) -> void:
	var direccion: Vector2 = Vector2.ZERO
	if puede_moverse:
		direccion = _obtener_direccion_input()
	mover(direccion)


func _al_cambiar_bloqueo(bloqueado: bool) -> void:
	puede_moverse = not bloqueado


## Lee las acciones de movimiento y regresa una sola dirección (sin diagonales).
func _obtener_direccion_input() -> Vector2:
	var dir_x: float = Input.get_axis("mover_izquierda", "mover_derecha")
	var dir_y: float = Input.get_axis("mover_arriba", "mover_abajo")
	if dir_x != 0.0:
		return Vector2(signf(dir_x), 0.0)
	if dir_y != 0.0:
		return Vector2(0.0, signf(dir_y))
	return Vector2.ZERO
