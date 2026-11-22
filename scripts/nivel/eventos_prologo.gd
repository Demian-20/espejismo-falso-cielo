extends Node2D
## Eventos del prólogo (#30, lo pendiente de #9 y #17). Vive en la raíz de nivel/objetos.tscn.
##
## - Disparador al cruzar hacia la Catedral: Mateo se detiene y empieza el encuentro con
##   Don Chente. Antes se guarda el punto de control para el "Reintentar".
## - Cuando Mateo decide si le da los $20, anochece: Tween sobre un CanvasModulate,
##   etapa NOCHE (ambiente nocturno) y la plaza se vacía.
## - Cuando el narco acorrala a Mateo en el callejón (#7), el desenlace depende de
##   GameState.ayudo_a_chente: Game Over (rama A) o Tezcatlipoca (rama B) y resultados.

const COLOR_DIA := Color(1, 1, 1)
const COLOR_NOCHE := Color(0.5, 0.55, 0.82)
## El fondo del callejón ya es oscuro, así que ahí la luz baja menos.
const COLOR_CALLEJON := Color(0.88, 0.88, 1.0)
const COLOR_SOMBRAS := Color(0.56, 0.5, 0.72)
## A partir de esta x el jugador está en la zona del callejón.
const X_CALLEJON := 2900.0

const RETRATO_MATEO := "res://assets/retratos/mateo_normal.png"
const RETRATO_MATEO_ASUSTADO := "res://assets/retratos/mateo_asustado.png"
const RETRATO_MATEO_CONFUNDIDO := "res://assets/retratos/mateo_confundido.png"
const RETRATO_CHENTE := "res://assets/retratos/don_chente_normal.png"
const RETRATO_NARCO := "res://assets/retratos/narco.png"
const RETRATO_TEZCATLIPOCA := "res://assets/retratos/tezcatlipoca.png"
const SPRITES_TEZCATLIPOCA := preload("res://assets/personajes/tezcatlipoca/tezcatlipoca.tres")
const VOZ_MATEO := 0.98
const VOZ_CHENTE := 0.85
const VOZ_NARCO := 0.7
const VOZ_TEZCATLIPOCA := 0.6
const VOZ_NARRADOR := 1.15
const MENSAJE_SIN_AYUDA := "Nadie acudió a tu llamado en la oscuridad del callejón."

var _plaza: Node
var _jugador: Jugador
var _chente: Node
var _callejon: Node
var _luz: CanvasModulate
var _velo: ColorRect
var _encuentro_activo: bool = false
var _anocheciendo: bool = false
var _desenlace_activo: bool = false

@onready var disparador: Area2D = $DisparadorChente


func _ready() -> void:
	_plaza = get_parent()
	_jugador = _plaza.get_node_or_null("Jugador") as Jugador
	_chente = _plaza.get_node_or_null("Npcs/DonChente")
	_callejon = _plaza.get_node_or_null("Callejon")
	_luz = CanvasModulate.new()
	_luz.color = COLOR_DIA
	add_child(_luz)
	_crear_velo()
	disparador.body_entered.connect(_al_cruzar)
	if _chente != null and _chente.has_signal("decision_tomada"):
		_chente.decision_tomada.connect(_al_decidir)
	if _callejon != null and _callejon.has_signal("mateo_acorralado"):
		_callejon.mateo_acorralado.connect(_desenlace)
	_conectar_zona_chente.call_deferred()
	if GameState.etapa_prologo >= GameState.Etapa.NOCHE:
		_luz.color = COLOR_NOCHE
		_vaciar_plaza.call_deferred(0.0)


func _process(delta: float) -> void:
	if _jugador == null or _anocheciendo or _desenlace_activo:
		return
	if GameState.etapa_prologo == GameState.Etapa.TARDE:
		return
	var objetivo := COLOR_CALLEJON if _jugador.global_position.x > X_CALLEJON else COLOR_NOCHE
	_luz.color = _luz.color.lerp(objetivo, minf(1.0, delta * 4.0))


# ---------------- Don Chente y el anochecer ----------------

func _conectar_zona_chente() -> void:
	var zona: Variant = _chente.get("zona_interaccion") if _chente != null else null
	if zona is Interactuable:
		(zona as Interactuable).interactuado.connect(_antes_de_hablar_con_chente)


## Si Mateo le habla a Don Chente con E antes de cruzar, también se guarda el punto de control.
func _antes_de_hablar_con_chente() -> void:
	if GameState.etapa_prologo == GameState.Etapa.TARDE and _jugador != null:
		GameState.guardar_punto_control(_jugador.global_position)


## Disparador obligatorio: al cruzar hacia la Catedral, Don Chente le habla a Mateo.
func _al_cruzar(cuerpo: Node2D) -> void:
	if not cuerpo is Jugador or _encuentro_activo or _chente == null:
		return
	if GameState.etapa_prologo != GameState.Etapa.TARDE:
		return
	_encuentro_activo = true
	# Reaparece un poco antes del disparador para volver a vivir el encuentro.
	GameState.guardar_punto_control(_jugador.global_position + Vector2(-70, 0))
	_jugador.puede_moverse = false
	await HUD.dialogo([
		HUD.linea("Mateo", "Voy a cruzar tantito para ver la iglesia de cerca antes de regresarme...", RETRATO_MATEO, VOZ_MATEO),
		HUD.linea("Don Chente", "Con cuidado al cruzar, muchacho... A veces uno camina embobado mirando las torres de allá arriba y no se fija en las sombras que se arrastran por el suelo.", RETRATO_CHENTE, VOZ_CHENTE),
	])
	await _chente.interactuar()
	_encuentro_activo = false


func _al_decidir(_ayudo: bool) -> void:
	if GameState.etapa_prologo != GameState.Etapa.TARDE:
		return
	await get_tree().create_timer(0.4).timeout
	_anocheciendo = true
	_jugador.puede_moverse = false
	HUD.notificar("Unos minutos después...", 2.5)
	GameState.etapa_prologo = GameState.Etapa.NOCHE
	_vaciar_plaza(2.5)
	var tween := create_tween()
	tween.tween_property(_luz, "color", COLOR_NOCHE, 3.0)
	await tween.finished
	_anocheciendo = false
	await HUD.dialogo([
		HUD.linea("Mateo", "Ya se hizo completamente de noche y definitivo no llegó. Ya me voy a mi casa...", RETRATO_MATEO, VOZ_MATEO),
		HUD.linea("Mateo", "Voy a cortar camino por el callejón para salir más rápido a la avenida.", RETRATO_MATEO, VOZ_MATEO),
	])
	_jugador.puede_moverse = true
	HUD.notificar("Objetivo: corta camino por el callejón, al final de la calle junto a las obras.", 6.0)


## De noche la plaza se vacía: se van los civiles y Doña Carmen. Cárdenas y Don Chente se quedan.
func _vaciar_plaza(segundos: float) -> void:
	var npcs := _plaza.get_node_or_null("Npcs")
	if npcs == null:
		return
	for hijo in npcs.get_children():
		var npc := hijo as NPCAmbiental
		if npc == null or npc.id_npc == "cardenas":
			continue
		npc.zona_interaccion.activo = false
		npc.set_physics_process(false)
		npc.collision_layer = 0
		if segundos <= 0.0:
			npc.visible = false
		else:
			var t := create_tween()
			t.tween_property(npc, "modulate:a", 0.0, segundos)
			t.tween_callback(npc.hide)


# ---------------- Desenlace (#17) ----------------

func _desenlace() -> void:
	if _desenlace_activo or _callejon == null:
		return
	_desenlace_activo = true
	var narco := _callejon.get("narco") as Narco
	# Espera a que termine el "¡Está cerrada con candado!" del callejón.
	while HUD.esta_en_dialogo():
		await get_tree().process_frame
	_encuadrar_desenlace()
	await get_tree().create_timer(0.8).timeout
	if GameState.ayudo_a_chente:
		await _rama_tezcatlipoca(narco)
	else:
		await _rama_game_over(narco)


## Rama A: nadie ayuda a Mateo. Disparo, animación de muerte y Game Over.
func _rama_game_over(narco: Narco) -> void:
	await HUD.dialogo([
		HUD.linea("Narco", "Hasta aquí llegaste por andar en el lugar equivocado, morro.", RETRATO_NARCO, VOZ_NARCO),
	])
	_jugador.puede_moverse = false
	narco.animacion.play("disparo_" + narco.ultima_direccion)
	Audio.reproducir("disparo")
	_destello(Color(1, 0.95, 0.85, 0.85), 0.35)
	_jugador.animacion.play("muerte")
	HUD.game_over.mensaje = MENSAJE_SIN_AYUDA
	await get_tree().create_timer(0.9).timeout
	GameState.perder_todas_las_vidas()


## Rama B: Don Chente aparece como Tezcatlipoca y el narco desaparece en las sombras.
func _rama_tezcatlipoca(narco: Narco) -> void:
	await HUD.dialogo([
		HUD.linea("Narco", "Hasta aquí llegaste por andar en el lugar equivocado, morro...", RETRATO_NARCO, VOZ_NARCO),
	])
	_jugador.puede_moverse = false
	# Las luces del callejón parpadean y se apagan.
	for i in 4:
		_luz.color = Color(0.04, 0.04, 0.07)
		await get_tree().create_timer(0.08).timeout
		_luz.color = COLOR_CALLEJON
		await get_tree().create_timer(0.14).timeout
	_luz.color = COLOR_SOMBRAS
	Audio.reproducir("vibracion", 0.0, 0.5)
	# Humo negro y Tezcatlipoca detrás del narco.
	var lugar := narco.global_position + Vector2(44, 28)
	var humo := _crear_humo(narco.get_parent(), lugar)
	var tez := AnimatedSprite2D.new()
	tez.sprite_frames = SPRITES_TEZCATLIPOCA
	tez.scale = Vector2(1.5, 1.5)
	tez.modulate.a = 0.0
	narco.get_parent().add_child(tez)
	tez.global_position = lugar + Vector2(0, -18)
	tez.play("idle_arriba")
	var aparicion := create_tween()
	aparicion.tween_property(tez, "modulate:a", 1.0, 1.4)
	await aparicion.finished
	narco.mirar_hacia(lugar)
	await HUD.dialogo([
		HUD.linea("Narco", "¡¿Qué demonios es eso?! ¡¿Quién anda ahí?!", RETRATO_NARCO, VOZ_NARCO),
	])
	_jugador.puede_moverse = false
	# Las sombras envuelven al narco.
	humo.global_position = narco.global_position
	Audio.reproducir("dano", -2.0, 0.6)
	var sombra := create_tween()
	sombra.tween_property(narco, "modulate", Color(0, 0, 0, 1), 0.6)
	sombra.tween_property(narco, "modulate:a", 0.0, 0.7)
	await sombra.finished
	narco.hide()
	narco.set_physics_process(false)
	humo.global_position = lugar
	_voltear_jugador_hacia(tez.global_position)
	await HUD.dialogo([
		HUD.linea("", "[i][color=#b0b5c4]El silencio regresa. Don Chente, envuelto en sombras y con un espejo de obsidiana en el pecho, mira a Mateo.[/color][/i]", null, VOZ_NARRADOR),
		HUD.linea("Mateo", "¿Don Chente...? ¿Era usted el de la plaza? ¿Qué acaba de hacer... quién es usted realmente?", RETRATO_MATEO_ASUSTADO, VOZ_MATEO),
		HUD.linea("Tezcatlipoca", "En las banquetas de esta ciudad me dicen Chente, muchacho... pero mi verdadero nombre es mucho más antiguo que Hermosillo.", RETRATO_TEZCATLIPOCA, VOZ_TEZCATLIPOCA),
		HUD.linea("Tezcatlipoca", "Soy Tezcatlipoca, el señor del espejo humeante y dueño de las sombras de la noche.", RETRATO_TEZCATLIPOCA, VOZ_TEZCATLIPOCA),
		HUD.linea("Mateo", "¿Un dios...? ¿Por qué me salvó la vida?", RETRATO_MATEO_CONFUNDIDO, VOZ_MATEO),
		HUD.linea("Tezcatlipoca", "Porque hace un rato, cuando tenías el ánimo por los suelos y apenas traías veinte pesos en la bolsa, decidiste tenderme la mano sin esperar nada a cambio.", RETRATO_TEZCATLIPOCA, VOZ_TEZCATLIPOCA),
		HUD.linea("Tezcatlipoca", "En mi espejo de obsidiana se ve el verdadero rostro de los hombres cuando creen que nadie los observa.", RETRATO_TEZCATLIPOCA, VOZ_TEZCATLIPOCA),
		HUD.linea("Tezcatlipoca", "Escúchame bien, Mateo. No estoy aquí para imponerte ninguna misión ni obligarte a nada.", RETRATO_TEZCATLIPOCA, VOZ_TEZCATLIPOCA),
		HUD.linea("Tezcatlipoca", "Pero hoy el falso cielo de esta ciudad se abrió frente a ti y viste lo que se oculta en sus callejones. Tienes en tus manos la posibilidad de hacer un gran cambio si decides buscar la verdad.", RETRATO_TEZCATLIPOCA, VOZ_TEZCATLIPOCA),
		HUD.linea("Tezcatlipoca", "Elijas lo que elijas, yo te estaré vigilando siempre desde las sombras.", RETRATO_TEZCATLIPOCA, VOZ_TEZCATLIPOCA),
	])
	_jugador.puede_moverse = false
	var salida := create_tween()
	salida.tween_property(tez, "modulate:a", 0.0, 2.0)
	await salida.finished
	humo.emitting = false
	tez.queue_free()
	await HUD.dialogo([
		HUD.linea("Mateo", "Tezcatlipoca... Si lo que dijo es cierto, lo que vi hoy aquí es apenas el principio.", RETRATO_MATEO, VOZ_MATEO),
	])
	_jugador.puede_moverse = false
	var final := create_tween()
	final.tween_property(_velo, "color:a", 1.0, 1.5)
	await final.finished
	HUD.mostrar_resultados()
	_velo.color.a = 0.0


## Aleja un poco la cámara y la baja, para que el narco y Tezcatlipoca (que están
## debajo de Mateo) no queden tapados por la caja de diálogo.
func _encuadrar_desenlace() -> void:
	var camara := _jugador.get_node_or_null("Camera2D") as Camera2D
	if camara == null:
		return
	var t := create_tween().set_parallel()
	t.tween_property(camara, "zoom", Vector2(2.0, 2.0), 0.8)
	t.tween_property(camara, "offset", Vector2(0, 100), 0.8)


## El humo va en la misma zona que los personajes, con z_index -1: encima del piso
## y detrás de ellos.
func _crear_humo(padre: Node, lugar: Vector2) -> CPUParticles2D:
	var humo := CPUParticles2D.new()
	humo.amount = 48
	humo.lifetime = 1.8
	humo.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	humo.emission_sphere_radius = 34.0
	humo.direction = Vector2(0, -1)
	humo.spread = 60.0
	humo.gravity = Vector2(0, -18)
	humo.initial_velocity_min = 8.0
	humo.initial_velocity_max = 26.0
	humo.scale_amount_min = 6.0
	humo.scale_amount_max = 14.0
	var rampa := Gradient.new()
	rampa.set_color(0, Color(0.02, 0.0, 0.05, 0.85))
	rampa.set_color(1, Color(0.12, 0.05, 0.18, 0.0))
	humo.color_ramp = rampa
	humo.z_index = -1
	padre.add_child(humo)
	humo.global_position = lugar
	humo.emitting = true
	return humo


func _voltear_jugador_hacia(punto: Vector2) -> void:
	var diferencia := punto - _jugador.global_position
	if absf(diferencia.x) > absf(diferencia.y):
		_jugador.ultima_direccion = "lado"
		_jugador.animacion.flip_h = diferencia.x < 0.0
	else:
		_jugador.ultima_direccion = "arriba" if diferencia.y < 0.0 else "abajo"
		_jugador.animacion.flip_h = false
	_jugador.animacion.play("idle_" + _jugador.ultima_direccion)


func _crear_velo() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 9
	add_child(capa)
	_velo = ColorRect.new()
	_velo.color = Color(0, 0, 0, 0)
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(_velo)


func _destello(color: Color, segundos: float) -> void:
	_velo.color = color
	var t := create_tween()
	t.tween_property(_velo, "color:a", 0.0, segundos)
