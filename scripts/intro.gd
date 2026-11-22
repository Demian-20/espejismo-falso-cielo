extends Control

const IMG_PANTALLA_1 := preload("res://assets/intro/01_hermosillo_atardecer.jpg")
const IMG_PANTALLA_2 := preload("res://assets/intro/02_plaza_tarde.jpg")
const IMG_BANCA := preload("res://assets/intro/03_mateo_banca.jpg")

const VOZ_NARRADOR := 1.15
const VOZ_MATEO := 0.98
const VOZ_VALERIA := 1.32
const VOZ_ANTONIO := 0.78

@onready var imagen: TextureRect = $Imagen
@onready var texto_pantalla: Label = $LabelTexto
@onready var telon: ColorRect = $Telon

var _fase: int = 0
var _puede_avanzar: bool = false


func _ready() -> void:
	HUD.mostrar_marcador(false)
	Audio.musica("plaza_tarde")
	_configurar_estilo_texto()
	telon.modulate.a = 1.0
	await _mostrar_pantalla_1()


func _configurar_estilo_texto() -> void:
	texto_pantalla.add_theme_font_size_override("font_size", 32)
	texto_pantalla.add_theme_color_override("font_color", Color.WHITE)
	texto_pantalla.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 0.95))
	texto_pantalla.add_theme_constant_override("outline_size", 8)


func _unhandled_input(event: InputEvent) -> void:
	if not _puede_avanzar:
		return
	var clic = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var tecla = event.is_action_pressed("interactuar") or event.is_action_pressed("ui_accept")
	if clic or tecla:
		get_viewport().set_input_as_handled()
		_avanzar_fase()


func _avanzar_fase() -> void:
	_puede_avanzar = false
	if _fase == 1:
		await _mostrar_pantalla_2()
	elif _fase == 2:
		await _mostrar_escena_banca()


func _escribir_texto(mensaje: String, con_aviso: bool = false) -> void:
	texto_pantalla.text = mensaje
	texto_pantalla.visible_characters = 0
	texto_pantalla.visible = true
	var total: int = mensaje.length()
	var duracion: float = total * 0.045
	var tween := create_tween()
	tween.tween_property(texto_pantalla, "visible_characters", total, duracion)
	await tween.finished
	if con_aviso:
		texto_pantalla.text = mensaje + "\n\n[Presiona Espacio / E o Clic]"
		texto_pantalla.visible_characters = -1


func _mostrar_pantalla_1() -> void:
	_fase = 1
	imagen.texture = IMG_PANTALLA_1
	texto_pantalla.visible = false
	await _fundido(0.0, 1.0)
	await _escribir_texto("Hermosillo, Sonora", true)
	_puede_avanzar = true


func _mostrar_pantalla_2() -> void:
	await _fundido(1.0, 0.6)
	_fase = 2
	imagen.texture = IMG_PANTALLA_2
	texto_pantalla.visible = false
	await _fundido(0.0, 0.8)
	await _escribir_texto("Plaza Zaragoza — 5:45 PM", false)
	_puede_avanzar = true


func _mostrar_escena_banca() -> void:
	await _fundido(1.0, 0.6)
	if not is_inside_tree():
		return
	_fase = 3
	imagen.texture = IMG_BANCA
	texto_pantalla.visible = false
	await _fundido(0.0, 0.8)
	if not is_inside_tree():
		return

	# --- Monólogo de Mateo en la banca ---
	await HUD.dialogo([
		HUD.linea("", "[i][color=#b0b5c4]Mateo suelta un largo suspiro mirando hacia el frente, antes de bajar la vista hacia su celular.[/color][/i]", null, VOZ_NARRADOR),
		HUD.linea("Mateo", "Uff... ya pasó casi una hora y todavía no llega.", null, VOZ_MATEO),
		HUD.linea("Mateo", "¿Será que le pasó algo en el camino... o simplemente me volvieron a dejar plantado por tercera vez?", null, VOZ_MATEO),
		HUD.linea("", "[i][color=#b0b5c4]Mateo vuelve a suspirar y se queda mirando el suelo, preguntándose si no estaría mejor aprovechando su tarde en cualquier otra cosa.[/color][/i]", null, VOZ_NARRADOR),
		HUD.linea("Mateo", "En fin... qué pérdida de tiempo.", null, VOZ_MATEO),
	])

	if not is_inside_tree():
		return
	await _fundido(1.0, 0.8)
	if not is_inside_tree():
		return
	get_tree().change_scene_to_file("res://scenes/plaza_zaragoza.tscn")


func _fundido(alpha_destino: float, duracion: float) -> void:
	var tween := create_tween()
	tween.tween_property(telon, "modulate:a", alpha_destino, duracion)
	await tween.finished
