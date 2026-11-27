extends Control

const IMG_PLAZA_NOCHE := preload("res://assets/intro/plaza_noche.jpg")
const IMG_MATEO_CELULAR := preload("res://assets/intro/Mateo celular.jpg")
const IMG_MATEO_CRISTAL := preload("res://assets/intro/Mateo piedra.jpg")
const RETRATO_MATEO := "res://assets/retratos/mateo_normal.png"
const ESCENA_CALLEJON := "res://scenes/nivel/callejon.tscn"

const VOZ_NARRADOR := 1.15
const VOZ_MATEO := 0.98

var _imagen: TextureRect
var _titulo: Label
var _telon: ColorRect


func _ready() -> void:
	HUD.mostrar_marcador(false)
	_construir_ui()
	await _reproducir_secuencia()


func _construir_ui() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 0
	add_child(capa)

	_imagen = TextureRect.new()
	_imagen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	capa.add_child(_imagen)

	_titulo = Label.new()
	_titulo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_titulo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_titulo.offset_top = 42
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.add_theme_font_size_override("font_size", 32)
	_titulo.add_theme_color_override("font_color", Color.WHITE)
	_titulo.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 0.95))
	_titulo.add_theme_constant_override("outline_size", 8)
	capa.add_child(_titulo)

	_telon = ColorRect.new()
	_telon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_telon.color = Color.BLACK
	_telon.modulate.a = 1.0
	_telon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(_telon)


func _reproducir_secuencia() -> void:
	# 1. Anochecer en Plaza Zaragoza (Mateo no sale en la imagen -> lleva retrato)
	_imagen.texture = IMG_PLAZA_NOCHE
	_titulo.text = "Plaza Zaragoza — 7:15 PM"
	_titulo.visible = true
	await _fundido(0.0, 0.9)

	await HUD.dialogo([
		HUD.linea("", "[i][color=#b0b5c4]La tarde termina de caer sobre el centro. El callejón junto a la catedral queda casi a oscuras.[/color][/i]", null, VOZ_NARRADOR),
		HUD.linea("Mateo", "Ya está completamente oscuro... si corto por aquí llego más rápido.", RETRATO_MATEO, VOZ_MATEO),
	])

	# 2. Mateo de lado caminando viendo el celular
	await _fundido(1.0, 0.6)
	_titulo.visible = false
	_imagen.texture = IMG_MATEO_CELULAR
	await _fundido(0.0, 0.8)

	await HUD.dialogo([
		HUD.linea("", "[i][color=#b0b5c4]Mateo camina por la calle solitaria revisando la pantalla de su celular.[/color][/i]", null, VOZ_NARRADOR),
		HUD.linea("Mateo", "Ni un mensaje nuevo... qué raro. Mejor apuro el paso.", null, VOZ_MATEO),
	])

	# 3. Mateo viendo el cristal en su mano (si ayudó a Don Chente)
	if GameState.ayudo_a_chente:
		await _fundido(1.0, 0.6)
		_imagen.texture = IMG_MATEO_CRISTAL
		await _fundido(0.0, 0.8)

		await HUD.dialogo([
			HUD.linea("", "[i][color=#b0b5c4]Al guardar el teléfono, siente un calor extraño en el bolsillo y saca la piedra que le dio Don Chente.[/color][/i]", null, VOZ_NARRADOR),
			HUD.linea("Mateo", "¿Y esto...? Parece obsidiana, pero está tibia... como si tuviera humo adentro.", null, VOZ_MATEO),
		])

	# 4. Salto a la escena del narco (callejon.tscn)
	await _fundido(1.0, 0.8)
	HUD.mostrar_marcador(true)
	get_tree().change_scene_to_file(ESCENA_CALLEJON)


func _fundido(alpha_destino: float, duracion: float) -> void:
	var tween := create_tween()
	tween.tween_property(_telon, "modulate:a", alpha_destino, duracion)
	await tween.finished
