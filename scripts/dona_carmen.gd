extends NPC

const RETRATO_CARMEN_NORMAL := "res://assets/retratos/dona_carmen_normal.png"
const RETRATO_CARMEN_TRISTE := "res://assets/retratos/dona_carmen_triste.png"
const RETRATO_CARMEN_AGRADECIDA := "res://assets/retratos/dona_carmen_agradecida.png"
const RETRATO_CARMEN_SERIA := "res://assets/retratos/dona_carmen_seria.png"
const RETRATO_MATEO_NORMAL := "res://assets/retratos/mateo_normal.png"
const RETRATO_MATEO_CONFUNDIDO := "res://assets/retratos/mateo_confundido.png"

const VOZ_CARMEN := 1.12
const VOZ_MATEO := 0.98

var _entrego_ficha: bool = false


func _ready() -> void:
	if nombre_mostrado == "":
		nombre_mostrado = "Doña Carmen"
	if id_npc == "":
		id_npc = "dona_carmen"
	super._ready()
	if animacion and animacion.sprite_frames and animacion.sprite_frames.has_animation("idle_lado"):
		animacion.play("idle_lado")
		animacion.flip_h = false


func interactuar() -> void:
	GameState.hablar_con_npc(id_npc)

	if GameState.tiene_evidencia("Ficha de Búsqueda de Doña Carmen"):
		await HUD.dialogo([
			HUD.linea("Doña Carmen", "Cuida esa libreta, mijo. Ahí están los nombres que nadie quiere ver.", RETRATO_CARMEN_SERIA, VOZ_CARMEN),
		])
		return

	await HUD.dialogo([
		HUD.linea("Doña Carmen", "Disculpa, joven... ¿No habrás visto a mi muchacho? Traigo su foto desde la mañana y aquí en Palacio nomás me dan largas.", RETRATO_CARMEN_TRISTE, VOZ_CARMEN),
		HUD.linea("Mateo", "¿Desde la mañana? ¿Y qué le dijeron adentro?", RETRATO_MATEO_CONFUNDIDO, VOZ_MATEO),
		HUD.linea("Doña Carmen", "Que 'todo está en orden', que regrese la otra semana... Pero yo misma anoté estas direcciones y placas antes de que nos corrieran.", RETRATO_CARMEN_SERIA, VOZ_CARMEN),
		HUD.linea("Doña Carmen", "Toma una copia, por favor. Si alguien pregunta, di que la encontraste tirada cerca del quiosco.", RETRATO_CARMEN_NORMAL, VOZ_CARMEN),
		HUD.linea("Mateo", "Descuide, señora. Voy a revisar qué hay detrás de esto.", RETRATO_MATEO_NORMAL, VOZ_MATEO),
		HUD.linea("Doña Carmen", "Dios te cuide, muchacho. De verdad gracias por no voltear la cara.", RETRATO_CARMEN_AGRADECIDA, VOZ_CARMEN),
	])

	if GameState.agregar_evidencia("Ficha de Búsqueda de Doña Carmen"):
		GameState.agregar_puntos(GameState.PUNTOS_FICHA_CARMEN)
