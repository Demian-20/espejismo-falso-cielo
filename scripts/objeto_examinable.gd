@tool
class_name ObjetoExaminable
extends Node2D

@export var texto_aviso: String = "Examinar"
@export_multiline var lineas: Array[String] = []
@export var retrato_mateo: Texture2D
@export var radio: float = 48.0:
	set(valor):
		radio = valor
		queue_redraw()
@export var tamano_caja: Vector2 = Vector2.ZERO:
	set(valor):
		tamano_caja = valor
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	var zona := Interactuable.new()
	zona.texto = texto_aviso
	zona.radio = radio

	if tamano_caja.x > 0.0 and tamano_caja.y > 0.0:
		var forma := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = tamano_caja
		forma.shape = rect
		zona.add_child(forma)

	add_child(zona)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var relleno := Color(0.0, 0.85, 1.0, 0.22)
	var borde := Color(0.0, 0.85, 1.0, 0.9)
	if tamano_caja.x > 0.0 and tamano_caja.y > 0.0:
		var rect := Rect2(-tamano_caja * 0.5, tamano_caja)
		draw_rect(rect, relleno, true)
		draw_rect(rect, borde, false, 2.0)
	else:
		draw_circle(Vector2.ZERO, radio, relleno)
		draw_arc(Vector2.ZERO, radio, 0.0, TAU, 32, borde, 2.0)


func interactuar() -> void:
	if lineas.is_empty():
		return
	var hud := get_node_or_null("/root/HUD")
	if hud == null:
		return
	var bloque: Array = []
	for texto in lineas:
		bloque.append(hud.linea("Mateo", texto, retrato_mateo, 0.98))
	await hud.dialogo(bloque)
