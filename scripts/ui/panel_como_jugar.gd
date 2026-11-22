class_name PanelComoJugar
extends PanelContainer
## Ayuda de "Cómo jugar" (#30): controles, objetivo, puntaje y vidas.
## La usan el menú principal y el menú de pausa.

signal cerrado

var _volver: Button


func _ready() -> void:
	add_theme_stylebox_override("panel", EstiloUI.panel(3, 24))
	var columna := VBoxContainer.new()
	columna.custom_minimum_size = Vector2(780, 0)
	columna.add_theme_constant_override("separation", 12)
	add_child(columna)
	var titulo := EstiloUI.etiqueta("CÓMO JUGAR", 32, EstiloUI.NOMBRE)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(titulo)
	var objetivo := EstiloUI.etiqueta("Explora la Plaza Zaragoza mientras esperas, habla con la gente y reúne evidencias. Lo que decidas con Don Chente cambia lo que pasa en el callejón.", 17, EstiloUI.TEXTO)
	objetivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(objetivo)
	var dos := HBoxContainer.new()
	dos.add_theme_constant_override("separation", 36)
	columna.add_child(dos)
	dos.add_child(_lista("Controles", [
		["WASD / Flechas", "Caminar"],
		["E", "Hablar, revisar y avanzar el diálogo"],
		["Shift / Espacio", "Correr (en la persecución)"],
		["Tab / I", "Inventario de evidencias"],
		["Esc / P", "Pausa"],
	]))
	dos.add_child(_lista("Puntaje y vidas", [
		["+50", "Hablar con alguien por primera vez"],
		["+100", "Ficha de Doña Carmen"],
		["+250", "Ayudar a Don Chente"],
		["+75", "Cada pista escondida (hay 3)"],
		["+300", "Escapar del narco"],
		["3 vidas", "El narco te quita una si te alcanza"],
	]))
	_volver = EstiloUI.boton("Volver")
	_volver.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_volver.pressed.connect(cerrar)
	columna.add_child(_volver)


func abrir() -> void:
	visible = true
	_volver.grab_focus()


func cerrar() -> void:
	visible = false
	cerrado.emit()


func _lista(titulo: String, filas: Array) -> VBoxContainer:
	var caja := VBoxContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_theme_constant_override("separation", 6)
	caja.add_child(EstiloUI.etiqueta(titulo, 20, EstiloUI.NOMBRE))
	for f in filas:
		var fila := HBoxContainer.new()
		var tecla := EstiloUI.etiqueta(str(f[0]), 16, EstiloUI.NOMBRE)
		tecla.custom_minimum_size = Vector2(130, 0)
		fila.add_child(tecla)
		var texto := EstiloUI.etiqueta(str(f[1]), 16, EstiloUI.TEXTO)
		texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(texto)
		caja.add_child(fila)
	return caja
