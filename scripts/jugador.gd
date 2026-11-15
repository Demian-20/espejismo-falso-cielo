class_name Jugador
extends CharacterBody2D

# Atributos de la clase (POO)
@export var velocidad: float = 160.0
var ultima_direccion: String = "abajo"

# Referencia al nodo hijo AnimatedSprite2D
@onready var animacion: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	var direccion: Vector2 = _obtener_direccion_input()
	velocity = direccion * velocidad
	move_and_slide()
	_actualizar_animacion(direccion)

# Método privado para leer las teclas (4 direcciones)
func _obtener_direccion_input() -> Vector2:
	var dir_x: float = Input.get_axis("ui_left", "ui_right")
	var dir_y: float = Input.get_axis("ui_up", "ui_down")
	
	# Soporte adicional para teclas W, A, S, D
	if Input.is_key_pressed(KEY_A): dir_x = -1.0
	if Input.is_key_pressed(KEY_D): dir_x = 1.0
	if Input.is_key_pressed(KEY_W): dir_y = -1.0
	if Input.is_key_pressed(KEY_S): dir_y = 1.0
	
	if dir_x != 0:
		return Vector2(dir_x, 0)
	elif dir_y != 0:
		return Vector2(0, dir_y)
	return Vector2.ZERO

# Método privado para controlar las animaciones y el espejeo (flip_h)
func _actualizar_animacion(direccion: Vector2) -> void:
	if direccion != Vector2.ZERO:
		if direccion.x > 0:
			ultima_direccion = "lado"
			animacion.flip_h = false
		elif direccion.x < 0:
			ultima_direccion = "lado"
			animacion.flip_h = true
		elif direccion.y < 0:
			ultima_direccion = "arriba"
			animacion.flip_h = false
		elif direccion.y > 0:
			ultima_direccion = "abajo"
			animacion.flip_h = false
		animacion.play("walk_" + ultima_direccion)
	else:
		animacion.play("idle_" + ultima_direccion)
