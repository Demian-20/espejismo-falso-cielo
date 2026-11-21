class_name NPC
extends Personaje
## Clase base reutilizable para NPCs (Issue #10).

@export var id_npc: String = ""

var _jugador_cerca: bool = false
var _interactuando: bool = false


func _ready() -> void:
	super._ready()
	if animacion and animacion.sprite_frames and animacion.sprite_frames.has_animation("idle_abajo"):
		animacion.play("idle_abajo")
	_crear_zona_interaccion()


func _crear_zona_interaccion() -> void:
	var zona := Area2D.new()
	zona.name = "ZonaInteraccion"
	zona.position = animacion.position if animacion else Vector2.ZERO
	zona.collision_layer = 0
	zona.collision_mask = 0xFFFFFFFF
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 100.0
	forma.shape = circulo
	zona.add_child(forma)
	add_child(zona)
	zona.body_entered.connect(_al_entrar)
	zona.body_exited.connect(_al_salir)


func _al_entrar(body: Node2D) -> void:
	print("Zona NPC detectó a: ", body.name)
	if body is Jugador or body.name == "Jugador":
		_jugador_cerca = true
		var etiqueta := nombre_mostrado if nombre_mostrado != "" else "NPC"
		HUD.mostrar_aviso("[E] Hablar con " + etiqueta)


func _al_salir(body: Node2D) -> void:
	if body is Jugador or body.name == "Jugador":
		_jugador_cerca = false
		HUD.ocultar_aviso()


func _unhandled_input(event: InputEvent) -> void:
	if not _jugador_cerca or _interactuando:
		return
	if HUD.esta_en_dialogo() or HUD.esta_en_pausa():
		return
	if event.is_action_pressed("interactuar"):
		get_viewport().set_input_as_handled()
		_interactuando = true
		HUD.ocultar_aviso()
		await interactuar()
		_interactuando = false
		if _jugador_cerca:
			var etiqueta := nombre_mostrado if nombre_mostrado != "" else "NPC"
			HUD.mostrar_aviso("[E] Hablar con " + etiqueta)


func interactuar() -> void:
	pass
