class_name Pista
extends Node2D
## Pista opcional tirada en la plaza (#30). Brilla un poco para que se note; al revisarla
## con E, Mateo dice lo que piensa, se guarda como evidencia y suma puntos.

const DESTELLO := preload("res://assets/pistas/destello.png")
const RETRATO_MATEO := "res://assets/retratos/mateo_confundido.png"
const VOZ_MATEO := 0.98

@export var evidencia: String = ""
@export var textura: Texture2D
@export_multiline var pensamiento: String = ""

var _sprite: Sprite2D
var _destello: Sprite2D
var _zona: Interactuable


func _ready() -> void:
	if GameState.tiene_evidencia(evidencia):
		queue_free()
		return
	_sprite = Sprite2D.new()
	_sprite.texture = textura
	_sprite.offset = Vector2(0, -textura.get_height() / 2.0 if textura else 0.0)
	add_child(_sprite)
	_destello = Sprite2D.new()
	_destello.texture = DESTELLO
	_destello.position = Vector2(8, -22)
	add_child(_destello)
	var brillo := create_tween().set_loops()
	brillo.tween_property(_destello, "modulate:a", 0.15, 0.7)
	brillo.parallel().tween_property(_destello, "scale", Vector2(0.6, 0.6), 0.7)
	brillo.tween_property(_destello, "modulate:a", 1.0, 0.7)
	brillo.parallel().tween_property(_destello, "scale", Vector2(1.0, 1.0), 0.7)
	_zona = Interactuable.new()
	_zona.texto = "Revisar"
	_zona.radio = 34.0
	add_child(_zona)


## La llama el jugador al presionar E.
func interactuar() -> void:
	_zona.activo = false
	await HUD.dialogo([HUD.linea("Mateo", pensamiento, RETRATO_MATEO, VOZ_MATEO)])
	if GameState.agregar_evidencia(evidencia):
		GameState.agregar_puntos(GameState.PUNTOS_PISTA)
		HUD.notificar("Pista encontrada: %s (+%d)" % [evidencia, GameState.PUNTOS_PISTA])
	queue_free()
