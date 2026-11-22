class_name Configuracion
extends RefCounted
## Opciones del jugador (volumen y pantalla completa). Se guardan en
## user://configuracion.cfg y se aplican al iniciar el juego desde el autoload Audio.

const RUTA := "user://configuracion.cfg"

## Volúmenes de 0.0 (mudo) a 1.0 (normal).
static var volumen_musica: float = 0.8
static var volumen_efectos: float = 1.0
static var pantalla_completa: bool = false


## Lee el archivo (si existe) y aplica las opciones.
static func cargar() -> void:
	var archivo := ConfigFile.new()
	if archivo.load(RUTA) == OK:
		volumen_musica = clampf(float(archivo.get_value("audio", "musica", volumen_musica)), 0.0, 1.0)
		volumen_efectos = clampf(float(archivo.get_value("audio", "efectos", volumen_efectos)), 0.0, 1.0)
		pantalla_completa = bool(archivo.get_value("video", "pantalla_completa", pantalla_completa))
	# En la web el navegador solo deja entrar a pantalla completa después de un clic.
	aplicar(not OS.has_feature("web"))


static func guardar() -> void:
	var archivo := ConfigFile.new()
	archivo.set_value("audio", "musica", volumen_musica)
	archivo.set_value("audio", "efectos", volumen_efectos)
	archivo.set_value("video", "pantalla_completa", pantalla_completa)
	archivo.save(RUTA)


static func aplicar(con_pantalla: bool = true) -> void:
	Audio.volumen_musica(_a_decibeles(volumen_musica))
	Audio.volumen_efectos(_a_decibeles(volumen_efectos))
	if not con_pantalla:
		return
	var modo := DisplayServer.WINDOW_MODE_FULLSCREEN if pantalla_completa else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != modo and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(modo)


## 1.0 = 0 dB (normal); 0.0 = -80 dB (mudo).
static func _a_decibeles(valor: float) -> float:
	return -80.0 if valor <= 0.001 else linear_to_db(valor)
