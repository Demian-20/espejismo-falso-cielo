extends NPC

const RETRATO_CHENTE_NORMAL := "res://assets/retratos/don_chente_normal.png"
const RETRATO_CHENTE_AGRADECIDO := "res://assets/retratos/don_chente_agradecido.png"
const RETRATO_CHENTE_SERIO := "res://assets/retratos/don_chente_serio.png"
const RETRATO_CHENTE_TRISTE := "res://assets/retratos/don_chente_triste.png"
const RETRATO_MATEO_NORMAL := "res://assets/retratos/mateo_normal.png"
const RETRATO_MATEO_SONRIENDO := "res://assets/retratos/mateo_sonriendo.png"

const VOZ_CHENTE := 0.85
const VOZ_MATEO := 0.98
const ESCENA_TRANSICION := "res://scenes/nivel/transicion_callejon.tscn"

var _cinematica_iniciada: bool = false


func _ready() -> void:
	if nombre_mostrado == "":
		nombre_mostrado = "Don Chente"
	if id_npc == "":
		id_npc = "don_chente"
	super._ready()
	if animacion and animacion.sprite_frames and animacion.sprite_frames.has_animation("idle_lado"):
		animacion.play("idle_lado")
		animacion.flip_h = false # mirando a la derecha hacia la banqueta
	_crear_zona_cinematica()


func _crear_zona_cinematica() -> void:
	var zona := Area2D.new()
	zona.name = "ZonaCinematica"
	# Caja solo en la banqueta frente a Don Chente (a su derecha), no atrás en el jardín
	zona.position = animacion.position + Vector2(52, 12)
	zona.collision_layer = 0
	zona.collision_mask = 0xFFFFFFFF
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(70, 80)
	forma.shape = rect
	zona.add_child(forma)
	add_child(zona)
	zona.body_entered.connect(_al_entrar_cinematica)


func _al_entrar_cinematica(body: Node2D) -> void:
	if _cinematica_iniciada:
		return
	if not (body is Jugador or body.name == "Jugador"):
		return
	_cinematica_iniciada = true
	_reproducir_cinematica(body as Personaje)


func _reproducir_cinematica(jugador: Personaje) -> void:
	HUD.ocultar_aviso()
	HUD._bloquear(true)

	# Mateo se detiene en la banqueta y voltea hacia Don Chente (sin chocar con bancas)
	if jugador:
		jugador.ultima_direccion = "lado"
		jugador.animacion.flip_h = jugador.global_position.x > global_position.x
		jugador.mover(Vector2.ZERO)

	if animacion:
		animacion.flip_h = jugador != null and jugador.global_position.x < global_position.x

	# 1. Signo "!" arriba de Don Chente
	await _mostrar_exclamacion()

	if not is_inside_tree():
		HUD._bloquear(false)
		return

	# 2. Diálogo y decisión con Don Chente
	await interactuar()

	# 3. Mateo comenta que ya está anocheciendo
	await HUD.dialogo([
		HUD.linea("Mateo", "Ya está anocheciendo... mejor me voy yendo antes de que se ponga más oscuro por aquí.", RETRATO_MATEO_NORMAL, VOZ_MATEO),
	])

	# 4. Fundido a negro
	await _fundido_a_negro()

	HUD._bloquear(false)
	if ResourceLoader.exists(ESCENA_TRANSICION):
		get_tree().change_scene_to_file(ESCENA_TRANSICION)
	else:
		print("Cinemática terminada (falta crear: ", ESCENA_TRANSICION, ")")


func _mostrar_exclamacion() -> void:
	var signo := Label.new()
	signo.text = "!"
	signo.add_theme_font_size_override("font_size", 28)
	signo.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
	signo.add_theme_color_override("font_outline_color", Color.BLACK)
	signo.add_theme_constant_override("outline_size", 6)
	signo.position = Vector2(-6, -68)
	add_child(signo)
	var tween := create_tween()
	tween.tween_property(signo, "position:y", -82.0, 0.25).set_trans(Tween.TRANS_BACK)
	await get_tree().create_timer(0.55).timeout
	signo.queue_free()


func _fundido_a_negro() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 100
	var telon := ColorRect.new()
	telon.color = Color.BLACK
	telon.modulate.a = 0.0
	telon.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(telon)
	get_tree().current_scene.add_child(capa)

	var tween := create_tween()
	tween.tween_property(telon, "modulate:a", 1.0, 0.9)
	await tween.finished


func interactuar() -> void:
	GameState.hablar_con_npc(id_npc)

	await HUD.dialogo([
		HUD.linea("Don Chente", "Treinta y ocho grados y ya se está metiendo el sol... Allá en la tele dicen que vivimos en Suiza, muchacho.", RETRATO_CHENTE_NORMAL, VOZ_CHENTE),
	])

	var opcion := await HUD.preguntar(
		HUD.linea("Don Chente", "Pero el hambre pega igualito que ayer. ¿No te sobrarán veinte pesitos pa' un bote de agua?", RETRATO_CHENTE_TRISTE, VOZ_CHENTE),
		["Darle los $20", "No darle nada"]
	)

	if opcion == 0:
		if GameState.ayudar_a_chente():
			GameState.agregar_evidencia("Obsidiana humeante")
			await HUD.dialogo([
				HUD.linea("Mateo", "Tenga, jefe. Cuídese en la noche.", RETRATO_MATEO_SONRIENDO, VOZ_MATEO),
				HUD.linea("Don Chente", "Buen corazón en tierra de coyotes. Toma esta piedra negra... cuando las sombras te acorralen, no estarás solo.", RETRATO_CHENTE_AGRADECIDO, VOZ_CHENTE),
			])
		else:
			await HUD.dialogo([
				HUD.linea("Don Chente", "Parece que ya no traes feria, muchacho...", RETRATO_CHENTE_TRISTE, VOZ_CHENTE),
			])
	else:
		GameState.ayudo_a_chente = false
		await HUD.dialogo([
			HUD.linea("Mateo", "Ando igual de bruja, jefe. A la vuelta.", RETRATO_MATEO_NORMAL, VOZ_MATEO),
			HUD.linea("Don Chente", "Cada quien camina con lo que carga... Ojalá no te toque pedir ayuda cuando nadie mire.", RETRATO_CHENTE_SERIO, VOZ_CHENTE),
		])
