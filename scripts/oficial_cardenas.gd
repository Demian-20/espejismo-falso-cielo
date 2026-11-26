extends NPC

const RETRATO_NORMAL := "res://assets/retratos/cardenas_normal.png"
const RETRATO_SERIO := "res://assets/retratos/cardenas_serio.png"
const RETRATO_PREOCUPADO := "res://assets/retratos/cardenas_preocupado.png"
const RETRATO_MATEO_NORMAL := "res://assets/retratos/mateo_normal.png"

const VOZ_CARDENAS := 0.88
const VOZ_MATEO := 0.98

@export var mirar_izquierda: bool = false

var _ya_hablo: bool = false


func _ready() -> void:
	if nombre_mostrado == "":
		nombre_mostrado = "Oficial Cárdenas"
	if id_npc == "":
		id_npc = "oficial_cardenas"
	super._ready()
	if animacion and animacion.sprite_frames and animacion.sprite_frames.has_animation("idle_lado"):
		animacion.play("idle_lado")
		animacion.flip_h = mirar_izquierda


func interactuar() -> void:
	GameState.hablar_con_npc(id_npc)

	if _ya_hablo:
		await HUD.dialogo([
			HUD.linea("Oficial Cárdenas", "Ya te dije, joven: el Palacio está cerrado y no deberías andar por aquí cuando caiga la noche.", RETRATO_SERIO, VOZ_CARDENAS),
		])
		return

	_ya_hablo = true
	await HUD.dialogo([
		HUD.linea("Oficial Cárdenas", "Alto ahí, muchacho. El Palacio Municipal está cerrado al público por órdenes de arriba.", RETRATO_SERIO, VOZ_CARDENAS),
		HUD.linea("Mateo", "¿Cerrado? Pero si apenas son las seis... ¿pasó algo adentro?", RETRATO_MATEO_NORMAL, VOZ_MATEO),
		HUD.linea("Oficial Cárdenas", "Mira... no me hagas hablar de más. Últimamente ha estado desapareciendo gente cerca del callejón.", RETRATO_PREOCUPADO, VOZ_CARDENAS),
		HUD.linea("Oficial Cárdenas", "Hazte un favor: no intentes entrar aquí y no te metas para allá atrás cuando oscurezca.", RETRATO_NORMAL, VOZ_CARDENAS),
	])
