class_name EstiloUI
extends RefCounted
## Colores y estilos compartidos por toda la interfaz (madera oscura con borde dorado).

const FONDO := Color(0.16, 0.12, 0.09, 0.94)
const FONDO_CLARO := Color(0.24, 0.18, 0.13, 1.0)
const FONDO_RESALTE := Color(0.36, 0.27, 0.17, 1.0)
const BORDE := Color(0.84, 0.67, 0.35)
const TEXTO := Color(0.95, 0.91, 0.83)
const NOMBRE := Color(0.95, 0.78, 0.43)
const TENUE := Color(0.72, 0.66, 0.58)
const ROJO := Color(0.85, 0.22, 0.2)


## Fondo con borde para paneles y cajas.
static func panel(borde: int = 3, margen: int = 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = FONDO
	s.border_color = BORDE
	s.set_border_width_all(borde)
	s.set_corner_radius_all(4)
	s.set_content_margin_all(margen)
	return s


static func etiqueta(texto: String, tamano: int, color: Color = TEXTO) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamano)
	l.add_theme_color_override("font_color", color)
	return l


## Botón para las opciones de diálogo: se resalta con el mouse y con el teclado (foco).
static func boton(texto: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 20)
	for estado in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		b.add_theme_color_override(estado, TEXTO)
	var normal := panel(1, 8)
	normal.bg_color = FONDO_CLARO
	normal.border_color = FONDO_CLARO
	var resalte := panel(2, 8)
	resalte.bg_color = FONDO_RESALTE
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", resalte)
	b.add_theme_stylebox_override("focus", resalte)
	b.add_theme_stylebox_override("pressed", resalte)
	b.focus_entered.connect(func() -> void: Audio.reproducir("seleccionar"))
	b.pressed.connect(func() -> void: Audio.reproducir("confirmar"))
	return b


## Crea una textura de pixel art a partir de un dibujo de texto (un carácter por píxel).
static func textura_pixeles(dibujo: Array[String], colores: Dictionary) -> ImageTexture:
	var img := Image.create(dibujo[0].length(), dibujo.size(), false, Image.FORMAT_RGBA8)
	for y in dibujo.size():
		for x in dibujo[y].length():
			var c: String = dibujo[y][x]
			img.set_pixel(x, y, colores.get(c, Color(0, 0, 0, 0)))
	return ImageTexture.create_from_image(img)
