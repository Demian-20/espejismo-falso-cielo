class_name NPC
extends Personaje
## Clase base reutilizable para NPCs (Issue #10).
##
## Crea su zona Interactuable (issue #8): el detector del jugador muestra
## "[E] Hablar con <nombre>" y al presionar E llama a interactuar(), que cada NPC sobrescribe.

## Radio de la zona para hablar, medido desde el cuerpo del NPC.
const RADIO_INTERACCION: float = 56.0

@export var id_npc: String = ""

var zona_interaccion: Interactuable


func _ready() -> void:
	super._ready()
	if animacion and animacion.sprite_frames and animacion.sprite_frames.has_animation("idle_abajo"):
		animacion.play("idle_abajo")
	_crear_zona_interaccion()


func _crear_zona_interaccion() -> void:
	zona_interaccion = Interactuable.new()
	zona_interaccion.name = "ZonaInteraccion"
	zona_interaccion.radio = RADIO_INTERACCION
	zona_interaccion.texto = "Hablar con " + (nombre_mostrado if nombre_mostrado != "" else "NPC")
	zona_interaccion.position = _centro_del_cuerpo()
	add_child(zona_interaccion)


## Centro del cuerpo del NPC. En algunas escenas el nodo se queda en (0, 0)
## y el sprite y la colisión se mueven, así que se toma la posición de la colisión.
func _centro_del_cuerpo() -> Vector2:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma != null:
		return forma.position
	return animacion.position if animacion else Vector2.ZERO


## La llama el jugador al presionar E. Cada NPC la sobrescribe con su diálogo.
func interactuar() -> void:
	pass
