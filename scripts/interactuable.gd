class_name Interactuable
extends Area2D
## Zona que el jugador puede usar con E (issue #8): un NPC, un objeto o una entrada.
##
## Cuando Mateo está cerca, el HUD muestra "[E] <texto>". Al presionar E se llama a
## interactuar() del nodo receptor (por defecto, el padre) y se emite `interactuado`.
##
## Ejemplo como hijo de un objeto que tiene su propio interactuar():
##   var zona := Interactuable.new()
##   zona.texto = "Revisar la ficha"
##   add_child(zona)

## Se emite cada vez que el jugador usa esta zona.
signal interactuado

## Capa de física 8 ("interactuables"); solo la revisa el detector del jugador.
const CAPA: int = 1 << 7

## Texto del aviso, sin el "[E]".
@export var texto: String = "Hablar"
## En false el jugador no la ve ni la puede usar (por ejemplo, el callejón de día).
@export var activo: bool = true
## Radio de la zona si no tiene un CollisionShape2D propio.
@export var radio: float = 48.0

## Nodo que recibe la llamada a interactuar(). Si es null, se usa el padre.
var receptor: Node = null


func _ready() -> void:
	collision_layer = CAPA
	collision_mask = 0
	monitoring = false
	monitorable = true
	if not _tiene_forma():
		var forma := CollisionShape2D.new()
		var circulo := CircleShape2D.new()
		circulo.radius = radio
		forma.shape = circulo
		add_child(forma)


## La llama el jugador al presionar E. Usar con await: termina cuando acaba la interacción.
func interactuar() -> void:
	interactuado.emit()
	var destino: Node = receptor if receptor != null else get_parent()
	if destino != null and destino.has_method("interactuar"):
		await destino.interactuar()


func _tiene_forma() -> bool:
	for hijo in get_children():
		if hijo is CollisionShape2D or hijo is CollisionPolygon2D:
			return true
	return false
