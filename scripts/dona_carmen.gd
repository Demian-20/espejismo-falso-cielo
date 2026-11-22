extends NPCAmbiental
## Doña Carmen, madre buscadora (#30, lo pendiente de #9): está junto al quiosco y le
## entrega a Mateo la ficha de búsqueda de su hijo (evidencia y +100 puntos).

const EVIDENCIA := "Ficha de Búsqueda de Doña Carmen"
const RETRATO_MATEO := "res://assets/retratos/mateo_normal.png"
const VOZ_MATEO := 0.98


func interactuar() -> void:
	hablando = true
	mover(Vector2.ZERO)
	var jugador := get_tree().current_scene.get_node_or_null("Jugador") as Node2D
	if jugador != null:
		_mirar_hacia(jugador.global_position)
	GameState.hablar_con_npc(id_npc)
	if GameState.tiene_evidencia(EVIDENCIA):
		await HUD.dialogo([
			HUD.linea(nombre_mostrado, "Gracias otra vez, muchacho. Si llega a saber algo, búsqueme aquí en la plaza.", retrato, voz),
		])
		hablando = false
		return
	await HUD.dialogo([
		HUD.linea(nombre_mostrado, "Buenas tardes, joven. Disculpe que le quite un minutito... Ando repartiendo las fichas de búsqueda de mi hijo, desapareció aquí en Hermosillo hace unos meses.", retrato, voz),
		HUD.linea(nombre_mostrado, "¿Me ayudaría guardando este volante por si llega a verlo en algún lado?", retrato, voz),
		HUD.linea("Mateo", "Claro que sí, señora. Yo lo guardo y me fijo bien. Ojalá que pronto tenga noticias de él.", RETRATO_MATEO, VOZ_MATEO),
		HUD.linea(nombre_mostrado, "Dios te bendiga, muchacho. Cuídate mucho cuando caiga la noche, que las calles ya no están para andar confiado.", retrato, voz),
	])
	if GameState.agregar_evidencia(EVIDENCIA):
		GameState.agregar_puntos(GameState.PUNTOS_FICHA_CARMEN)
		HUD.notificar("Evidencia obtenida: %s (+%d)" % [EVIDENCIA, GameState.PUNTOS_FICHA_CARMEN])
	hablando = false
