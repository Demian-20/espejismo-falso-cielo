extends Node
## Música ambiental y efectos de sonido (autoload "Audio").
##
## Ejemplos desde otros scripts:
##   Audio.reproducir("disparo")
##   Audio.reproducir("paso", -6.0, randf_range(0.9, 1.1))
##   Audio.musica("tension")       # cambia de ambiente con un fundido
##   Audio.detener_musica()
##
## Los sonidos de los eventos de GameState (evidencia, monedas, daño y Game Over)
## suenan solos; no hace falta llamarlos.
##
## Efectos en assets/audio/sfx/: paso, letra, seleccionar, confirmar, evidencia, monedas,
## dano, game_over, disparo, vibracion, notificacion, sirena_lejana.
## Ambientes en bucle en assets/audio/ambiente/: plaza_tarde, plaza_noche, tension, motor_ralenti.

## Se emite cada vez que suena un efecto (útil para depurar).
signal sonido_reproducido(nombre: String)

const RUTA_EFECTOS := "res://assets/audio/sfx/%s.wav"
const RUTA_AMBIENTES := "res://assets/audio/ambiente/%s.wav"
## Segundos del fundido entre ambientes.
const FUNDIDO := 1.5
## Efectos que pueden sonar al mismo tiempo.
const CANALES := 8
const SILENCIO_DB := -40.0

var musica_actual: String = ""

var _canales: Array[AudioStreamPlayer] = []
var _siguiente: int = 0
var _musica_activa: AudioStreamPlayer
var _musica_libre: AudioStreamPlayer
var _cache: Dictionary = {}
var _evidencias_previas: int = 0
var _vidas_previas: int = 0
var _dinero_previo: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Los buses Musica y Efectos vienen de default_bus_layout.tres. En la versión web, crearlos
	# por código deja mal conectadas sus salidas y no se escucha nada (#45).
	if AudioServer.get_bus_index("Musica") == -1 or AudioServer.get_bus_index("Efectos") == -1:
		push_warning("Audio: faltan los buses de default_bus_layout.tres; se crean por código")
		_crear_bus("Musica", -4.0)
		_crear_bus("Efectos", 0.0)
	for i in CANALES:
		var canal := AudioStreamPlayer.new()
		canal.bus = "Efectos"
		add_child(canal)
		_canales.append(canal)
	_musica_activa = _reproductor_musica()
	_musica_libre = _reproductor_musica()
	_evidencias_previas = GameState.evidencias.size()
	_vidas_previas = GameState.vidas
	_dinero_previo = GameState.dinero
	GameState.evidencias_cambio.connect(_al_cambiar_evidencias)
	GameState.vidas_cambio.connect(_al_cambiar_vidas)
	GameState.dinero_cambio.connect(_al_cambiar_dinero)
	GameState.game_over.connect(_al_game_over)
	Configuracion.cargar()


## Reproduce un efecto de assets/audio/sfx/ por su nombre (sin ".wav").
func reproducir(nombre: String, volumen_db: float = 0.0, tono: float = 1.0) -> void:
	var stream := _cargar(RUTA_EFECTOS % nombre)
	if stream == null:
		push_warning("Audio: no existe el efecto '%s'" % nombre)
		return
	var canal := _canales[_siguiente]
	_siguiente = (_siguiente + 1) % CANALES
	canal.stream = stream
	canal.volume_db = volumen_db
	canal.pitch_scale = tono
	canal.play()
	sonido_reproducido.emit(nombre)


## Cambia el ambiente en bucle con un fundido. Si ya está sonando, no hace nada.
func musica(nombre: String, fundido: float = FUNDIDO) -> void:
	if nombre == musica_actual:
		return
	var stream := _cargar(RUTA_AMBIENTES % nombre)
	if stream == null:
		push_warning("Audio: no existe el ambiente '%s'" % nombre)
		return
	musica_actual = nombre
	var saliente := _musica_activa
	_musica_activa = _musica_libre
	_musica_libre = saliente
	_musica_activa.stream = stream
	_musica_activa.volume_db = SILENCIO_DB
	_musica_activa.play()
	var tween := create_tween().set_parallel()
	tween.tween_property(_musica_activa, "volume_db", 0.0, fundido)
	if saliente.playing:
		tween.tween_property(saliente, "volume_db", SILENCIO_DB, fundido)
		tween.chain().tween_callback(saliente.stop)


## Apaga el ambiente con un fundido.
func detener_musica(fundido: float = FUNDIDO) -> void:
	musica_actual = ""
	var reproductor := _musica_activa
	if not reproductor.playing:
		return
	var tween := create_tween()
	tween.tween_property(reproductor, "volume_db", SILENCIO_DB, fundido)
	tween.tween_callback(reproductor.stop)


## Regresa el stream de un ambiente, por ejemplo para un AudioStreamPlayer2D
## con sonido posicional (el motor de una camioneta en el callejón).
func ambiente(nombre: String) -> AudioStream:
	return _cargar(RUTA_AMBIENTES % nombre)


## Volumen de cada bus en decibeles (0 = normal, -80 = mudo).
func volumen_musica(db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Musica"), db)


func volumen_efectos(db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Efectos"), db)


func _al_cambiar_evidencias(evidencias: Array[String]) -> void:
	if evidencias.size() > _evidencias_previas:
		reproducir("evidencia")
	_evidencias_previas = evidencias.size()


func _al_cambiar_vidas(vidas: int) -> void:
	if vidas < _vidas_previas and vidas > 0:
		reproducir("dano")
	_vidas_previas = vidas


func _al_cambiar_dinero(dinero: int) -> void:
	if dinero < _dinero_previo:
		reproducir("monedas")
	_dinero_previo = dinero


func _al_game_over() -> void:
	reproducir("game_over")
	detener_musica(0.8)


func _cargar(ruta: String) -> AudioStream:
	if not _cache.has(ruta):
		_cache[ruta] = load(ruta) if ResourceLoader.exists(ruta) else null
	return _cache[ruta]


func _reproductor_musica() -> AudioStreamPlayer:
	var r := AudioStreamPlayer.new()
	r.bus = "Musica"
	add_child(r)
	return r


func _crear_bus(nombre: String, volumen_db: float) -> void:
	if AudioServer.get_bus_index(nombre) != -1:
		return
	AudioServer.add_bus()
	var indice := AudioServer.bus_count - 1
	AudioServer.set_bus_name(indice, nombre)
	AudioServer.set_bus_send(indice, "Master")
	AudioServer.set_bus_volume_db(indice, volumen_db)
