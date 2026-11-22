extends Node
## Estado global de la partida (autoload "GameState").
##
## Guarda el puntaje, las vidas, el dinero, las evidencias y el progreso del prólogo.
## Cada cambio emite una señal, así el HUD, el Game Over y los demás sistemas reaccionan
## sin que nadie tenga que editar los scripts de otro.
##
## Ejemplos desde otros scripts:
##   GameState.agregar_puntos(GameState.PUNTOS_FICHA_CARMEN)
##   GameState.perder_vida()
##   GameState.puntaje_cambio.connect(_al_cambiar_puntaje)

## Se emite cuando cambia el puntaje. `diferencia` es lo que se sumó o restó.
signal puntaje_cambio(puntaje: int, diferencia: int)
## Se emite cuando cambian las vidas.
signal vidas_cambio(vidas: int)
## Se emite cuando cambia el dinero.
signal dinero_cambio(dinero: int)
## Se emite cuando se agrega una evidencia; recibe una copia de la lista completa.
signal evidencias_cambio(evidencias: Array[String])
## Se emite cuando cambia la etapa del prólogo (tarde, noche o persecución).
signal etapa_cambio(etapa: int)
## Se emite una vez cuando las vidas llegan a 0.
signal game_over
## Se emite al cargar un punto de control, con la posición guardada del jugador.
signal punto_control_cargado(posicion: Vector2)

## Etapas del prólogo según el guion.
enum Etapa { TARDE, NOCHE, PERSECUCION }

const VIDAS_INICIALES: int = 3
const DINERO_INICIAL: int = 20

## Puntos del prólogo.
const PUNTOS_FICHA_CARMEN: int = 100
const PUNTOS_AYUDAR_CHENTE: int = 250
const PUNTOS_HABLAR_NPC: int = 50
const PUNTOS_ESCAPAR_NARCO: int = 300
const PUNTOS_PISTA: int = 75
## Pistas opcionales escondidas en la plaza.
const TOTAL_PISTAS: int = 3
## Personas de la plaza con las que se puede hablar (Don Chente, Doña Carmen, Cárdenas y 3 civiles).
const TOTAL_NPCS: int = 6

## Lo que Mateo le da a Don Chente.
const DINERO_PARA_CHENTE: int = 20

## Archivo de la partida guardada (en la carpeta de datos del usuario).
const RUTA_PARTIDA: String = "user://partida.json"

var puntaje: int = 0:
	set(valor):
		var anterior := puntaje
		puntaje = maxi(valor, 0)
		if puntaje != anterior:
			puntaje_cambio.emit(puntaje, puntaje - anterior)

var vidas: int = VIDAS_INICIALES:
	set(valor):
		var anterior := vidas
		vidas = clampi(valor, 0, VIDAS_INICIALES)
		if vidas != anterior:
			vidas_cambio.emit(vidas)
			if vidas == 0:
				game_over.emit()

var dinero: int = DINERO_INICIAL:
	set(valor):
		var anterior := dinero
		dinero = maxi(valor, 0)
		if dinero != anterior:
			dinero_cambio.emit(dinero)

var evidencias: Array[String] = []

## true si Mateo le dio los $20 a Don Chente; decide el desenlace del callejón.
var ayudo_a_chente: bool = false

var etapa_prologo: int = Etapa.TARDE:
	set(valor):
		if valor != etapa_prologo:
			etapa_prologo = valor
			etapa_cambio.emit(etapa_prologo)

## true cuando ya sonaron las llamadas de Valeria y Antonio al llegar a la plaza (#15).
## No se reinicia al reintentar, solo con una partida nueva.
var llamadas_iniciales_vistas: bool = false

## NPCs con los que ya se habló, para dar los +50 puntos solo la primera vez.
var _npcs_hablados: Array[String] = []
var _punto_control: Dictionary = {}
## Posición donde debe aparecer el jugador después de cargar un punto de control.
var _posicion_pendiente: Variant = null


## Suma (o resta, con un número negativo) puntos al puntaje. El puntaje nunca baja de 0.
func agregar_puntos(cantidad: int) -> void:
	puntaje += cantidad


## Quita una vida. Con 0 vidas se emite `game_over`. Regresa las vidas que quedan.
func perder_vida() -> int:
	vidas -= 1
	return vidas


## Deja las vidas en 0 de golpe (por ejemplo, el disparo del desenlace sin Don Chente).
func perder_todas_las_vidas() -> void:
	vidas = 0


## Agrega una evidencia al inventario. Regresa false si ya estaba.
func agregar_evidencia(nombre: String) -> bool:
	if nombre in evidencias:
		return false
	evidencias.append(nombre)
	evidencias_cambio.emit(evidencias.duplicate())
	return true


func tiene_evidencia(nombre: String) -> bool:
	return nombre in evidencias


## Gasta dinero si alcanza. Regresa false (y no gasta nada) si no hay suficiente.
func gastar_dinero(cantidad: int) -> bool:
	if cantidad < 0 or cantidad > dinero:
		return false
	dinero -= cantidad
	return true


## Transacción con Don Chente: le da los $20, marca la ayuda y suma los puntos.
## Regresa false si Mateo ya no tiene el dinero.
func ayudar_a_chente() -> bool:
	if ayudo_a_chente or not gastar_dinero(DINERO_PARA_CHENTE):
		return false
	ayudo_a_chente = true
	agregar_puntos(PUNTOS_AYUDAR_CHENTE)
	return true


## Registra que se habló con un NPC y da +50 puntos solo la primera vez.
## Regresa true si fue la primera vez.
func hablar_con_npc(id_npc: String) -> bool:
	if id_npc in _npcs_hablados:
		return false
	_npcs_hablados.append(id_npc)
	agregar_puntos(PUNTOS_HABLAR_NPC)
	return true


## Cuántas personas distintas de la plaza ya hablaron con Mateo.
func npcs_hablados() -> int:
	return _npcs_hablados.size()


## Guarda una copia del estado actual y la posición del jugador para el "Reintentar".
func guardar_punto_control(posicion_jugador: Vector2 = Vector2.ZERO) -> void:
	_punto_control = {
		"puntaje": puntaje,
		"vidas": vidas,
		"dinero": dinero,
		"evidencias": evidencias.duplicate(),
		"ayudo_a_chente": ayudo_a_chente,
		"etapa_prologo": etapa_prologo,
		"npcs_hablados": _npcs_hablados.duplicate(),
		"posicion": posicion_jugador,
	}


func hay_punto_control() -> bool:
	return not _punto_control.is_empty()


## Regresa el estado al último punto de control y devuelve la posición guardada del jugador.
## Si no hay punto de control, reinicia la partida y devuelve Vector2.ZERO.
func cargar_punto_control() -> Vector2:
	if _punto_control.is_empty():
		reiniciar()
		return Vector2.ZERO
	var p := _punto_control
	puntaje = p["puntaje"]
	vidas = p["vidas"]
	dinero = p["dinero"]
	evidencias.assign(p["evidencias"])
	evidencias_cambio.emit(evidencias.duplicate())
	ayudo_a_chente = p["ayudo_a_chente"]
	etapa_prologo = p["etapa_prologo"]
	_npcs_hablados.assign(p["npcs_hablados"])
	if p["posicion"] != Vector2.ZERO:
		_posicion_pendiente = p["posicion"]
	punto_control_cargado.emit(p["posicion"])
	return p["posicion"]


## Regresa la posición de reaparición pendiente (o null) y la borra.
## La usa el jugador al aparecer después de "Reintentar".
func tomar_posicion_pendiente() -> Variant:
	var posicion: Variant = _posicion_pendiente
	_posicion_pendiente = null
	return posicion


## Deja todo como al empezar una partida nueva y borra el punto de control.
func reiniciar() -> void:
	puntaje = 0
	vidas = VIDAS_INICIALES
	dinero = DINERO_INICIAL
	evidencias.clear()
	evidencias_cambio.emit(evidencias.duplicate())
	ayudo_a_chente = false
	etapa_prologo = Etapa.TARDE
	_npcs_hablados.clear()
	_punto_control.clear()
	_posicion_pendiente = null


## Empieza una partida nueva desde la intro: reinicia todo, incluidas las llamadas.
func nueva_partida() -> void:
	reiniciar()
	llamadas_iniciales_vistas = false


## Solo se puede guardar de tarde, mientras Mateo explora la plaza.
## De noche y en el callejón la historia ya está en el desenlace.
func puede_guardar() -> bool:
	return etapa_prologo == Etapa.TARDE


func hay_partida_guardada() -> bool:
	return FileAccess.file_exists(RUTA_PARTIDA)


## Guarda la partida en disco con la escena y la posición del jugador.
## Regresa false si no se puede guardar en este momento o si falló el archivo.
func guardar_partida(escena: String, posicion_jugador: Vector2) -> bool:
	if not puede_guardar() or escena == "":
		return false
	var datos := {
		"version": 1,
		"fecha": Time.get_datetime_string_from_system(false, true),
		"escena": escena,
		"posicion": [posicion_jugador.x, posicion_jugador.y],
		"puntaje": puntaje,
		"vidas": vidas,
		"dinero": dinero,
		"evidencias": evidencias.duplicate(),
		"ayudo_a_chente": ayudo_a_chente,
		"etapa_prologo": etapa_prologo,
		"npcs_hablados": _npcs_hablados.duplicate(),
		"llamadas_iniciales_vistas": llamadas_iniciales_vistas,
	}
	var archivo := FileAccess.open(RUTA_PARTIDA, FileAccess.WRITE)
	if archivo == null:
		return false
	archivo.store_string(JSON.stringify(datos, "\t"))
	return true


## Fecha de la partida guardada (o "" si no hay), para mostrarla en el menú.
func fecha_partida_guardada() -> String:
	var datos := _leer_partida()
	return str(datos.get("fecha", ""))


## Carga la partida guardada y regresa la escena donde hay que aparecer (o "" si no hay).
## El jugador aparece en su posición guardada y esa partida queda como punto de control.
func cargar_partida() -> String:
	var datos := _leer_partida()
	if datos.is_empty():
		return ""
	reiniciar()
	puntaje = int(datos.get("puntaje", 0))
	vidas = int(datos.get("vidas", VIDAS_INICIALES))
	dinero = int(datos.get("dinero", DINERO_INICIAL))
	var lista: Array = datos.get("evidencias", [])
	for e in lista:
		evidencias.append(str(e))
	evidencias_cambio.emit(evidencias.duplicate())
	ayudo_a_chente = bool(datos.get("ayudo_a_chente", false))
	etapa_prologo = int(datos.get("etapa_prologo", Etapa.TARDE))
	var hablados: Array = datos.get("npcs_hablados", [])
	for n in hablados:
		_npcs_hablados.append(str(n))
	llamadas_iniciales_vistas = bool(datos.get("llamadas_iniciales_vistas", true))
	var p: Array = datos.get("posicion", [0, 0])
	var posicion := Vector2(float(p[0]), float(p[1]))
	if posicion != Vector2.ZERO:
		_posicion_pendiente = posicion
	guardar_punto_control(posicion)
	return str(datos.get("escena", ""))


func _leer_partida() -> Dictionary:
	if not hay_partida_guardada():
		return {}
	var texto := FileAccess.get_file_as_string(RUTA_PARTIDA)
	var datos: Variant = JSON.parse_string(texto)
	if datos is Dictionary:
		return datos
	return {}
