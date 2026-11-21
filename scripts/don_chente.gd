extends NPC

const RETRATO_CHENTE_NORMAL := "res://assets/retratos/don_chente_normal.png"
const RETRATO_CHENTE_AGRADECIDO := "res://assets/retratos/don_chente_agradecido.png"
const RETRATO_CHENTE_SERIO := "res://assets/retratos/don_chente_serio.png"
const RETRATO_CHENTE_TRISTE := "res://assets/retratos/don_chente_triste.png"
const RETRATO_MATEO_NORMAL := "res://assets/retratos/mateo_normal.png"
const RETRATO_MATEO_SONRIENDO := "res://assets/retratos/mateo_sonriendo.png"

const VOZ_CHENTE := 0.85
const VOZ_MATEO := 0.98


func _ready() -> void:
	if nombre_mostrado == "":
		nombre_mostrado = "Don Chente"
	if id_npc == "":
		id_npc = "don_chente"
	super._ready()
	if animacion and animacion.sprite_frames and animacion.sprite_frames.has_animation("idle_lado"):
		animacion.play("idle_lado")
		animacion.flip_h = false # cámbialo a true si quieres que mire hacia la izquierda


func interactuar() -> void:
	GameState.hablar_con_npc(id_npc)

	if GameState.ayudo_a_chente:
		await HUD.dialogo([
			HUD.linea("Don Chente", "Guarda bien esa piedra, muchacho. Esta noche el espejo te va a devolver el favor.", RETRATO_CHENTE_AGRADECIDO, VOZ_CHENTE),
		])
		return

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
