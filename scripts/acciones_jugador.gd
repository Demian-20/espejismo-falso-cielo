class_name AccionesJugador
extends Node
## Acciones del jugador: interactuar y correr (issue #8).
## Vive en un nodo hijo de Jugador para trabajarlo sin editar jugador.gd.

@onready var jugador: Jugador = get_parent() as Jugador
