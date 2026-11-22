extends Node2D
## Escena de la Plaza Zaragoza. Cambia el ambiente sonoro según la etapa del prólogo:
## tarde, noche y persecución. El issue #9 solo tiene que cambiar GameState.etapa_prologo.

const VOZ_NARRADOR := 1.15
const VOZ_MATEO := 0.98
const VOZ_VALERIA := 1.32
const VOZ_ANTONIO := 0.78


func _ready() -> void:
	GameState.etapa_cambio.connect(_al_cambiar_etapa)
	_al_cambiar_etapa(GameState.etapa_prologo)
	if not GameState.llamadas_iniciales_vistas:
		GameState.llamadas_iniciales_vistas = true
		await _reproducir_llamadas_iniciales()
	else:
		HUD.mostrar_marcador(true)


func _al_cambiar_etapa(etapa: int) -> void:
	if etapa == GameState.Etapa.NOCHE:
		Audio.musica("plaza_noche")
	elif etapa == GameState.Etapa.PERSECUCION:
		Audio.musica("tension")
	else:
		Audio.musica("plaza_tarde")


func _reproducir_llamadas_iniciales() -> void:
	HUD.mostrar_marcador(false)
	await get_tree().create_timer(0.4).timeout

	# --- Llamada 1: Valeria ---
	Audio.reproducir("vibracion")
	await get_tree().create_timer(0.5).timeout
	Audio.reproducir("notificacion")

	await HUD.dialogo([
		HUD.linea("", "[i][color=#b0b5c4]El teléfono vibra en sus manos. En la pantalla aparece una llamada entrante de Valeria.[/color][/i]", null, VOZ_NARRADOR),
		HUD.linea("Valeria", "¡Hola, Mateo! Oye, ¿cómo te fue con tu cita? Quería saber si ya ibas de regreso a tu casa...", "res://assets/retratos/valeria_alegre.png", VOZ_VALERIA),
		HUD.linea("Valeria", "...para ver si podía pasar a verte un rato, ya sabes.. muy rara vez nos vemos y-", "res://assets/retratos/valeria_sonrojada.png", VOZ_VALERIA),
		HUD.linea("Mateo", "No... sigo aquí en la Plaza Zaragoza. Todavía estoy esperando.", "res://assets/retratos/mateo_normal.png", VOZ_MATEO),
		HUD.linea("Valeria", "¿Qué? ¿Sigues ahí?! Pero si ya pasó muchísimo tiempo...", "res://assets/retratos/valeria_preocupada.png", VOZ_VALERIA),
		HUD.linea("Valeria", "Oye, ya se está haciendo bastante tarde y dicen que no conviene quedarse solo por esa zona de noche... ¿Seguro que no prefieres irte ya?", "res://assets/retratos/valeria_preocupada.png", VOZ_VALERIA),
		HUD.linea("", "[i][color=#b0b5c4]Mateo apenas le presta atención a la advertencia; el cansancio le pesa más que la precaución, aunque intenta no sonar grosero con ella.[/color][/i]", null, VOZ_NARRADOR),
		HUD.linea("Mateo", "Sí, sí, tranquila... Tampoco es como que tenga algo mejor que hacer ahorita. Podría irme a hacer otra cosa, pero la verdad ni ganas tengo.", "res://assets/retratos/mateo_normal.png", VOZ_MATEO),
		HUD.linea("Valeria", "Bueno, ¡ánimo! A lo mejor nada más se le hizo tarde el camión o... eh... bueno, tampoco es el fin del mundo, ¿no?", "res://assets/retratos/valeria_sonriendo.png", VOZ_VALERIA),
		HUD.linea("", "[i][color=#b0b5c4]Valeria se queda un segundo en silencio, un poco apenada por lo torpe que sonó su intento de animarlo.[/color][/i]", null, VOZ_NARRADOR),
		HUD.linea("Valeria", "Este... ¡ah! Perdón, me están hablando acá en mi casa, tengo que colgar. ¡Cuídate mucho, Mateo, por favor! Bye.", "res://assets/retratos/valeria_incomoda.png", VOZ_VALERIA),
	])


	# --- Llamada 2: Antonio ---
	await get_tree().create_timer(0.6).timeout
	Audio.reproducir("vibracion")
	await get_tree().create_timer(0.5).timeout
	Audio.reproducir("notificacion")

	await HUD.dialogo([
		HUD.linea("", "[i][color=#b0b5c4]Apenas cuelga, el celular vuelve a sonar. Esta vez es Antonio.[/color][/i]", null, VOZ_NARRADOR),
		HUD.linea("Antonio", "¡Qué onda, bro! ¿Cómo andas? ¿Dónde andas metido?", "res://assets/retratos/antonio_alegre.png", VOZ_ANTONIO),
		HUD.linea("Mateo", "Aquí en la Plaza Zaragoza... todavía esperando. Ya sabes, me volvieron a dejar plantado.", "res://assets/retratos/mateo_normal.png", VOZ_MATEO),
		HUD.linea("Antonio", "¡N'hombre, carnal! A este paso de tanto que te dejan plantado te van a salir raíces y te vas a volver un árbol de bellotas gigante ahí en medio de la plaza, jajaja.", "res://assets/retratos/antonio_burlon.png", VOZ_ANTONIO),
		HUD.linea("", "[i][color=#b0b5c4]Mateo suelta una pequeña risa cansada, relajando un poco el gesto.[/color][/i]", null, VOZ_NARRADOR),
		HUD.linea("Mateo", "Jajaja, qué gracioso... Ojalá, al menos así daría sombra. ¿Y tú qué onda, por qué marcas?", "res://assets/retratos/mateo_sonriendo.png", VOZ_MATEO),
		HUD.linea("Antonio", "No, nada, nomás pasaba por aquí cerca y... pues la neta ya se está haciendo bien noche, bro. Si ya te dejaron plantado, mejor ya vete a tu casa, ¿no?", "res://assets/retratos/antonio_normal.png", VOZ_ANTONIO),
		HUD.linea("Antonio", "Además, los camiones ya casi dejan de pasar a esta hora, te vas a quedar varado.", "res://assets/retratos/antonio_serio.png", VOZ_ANTONIO),
		HUD.linea("Mateo", "¿Cómo que ya no pasan? Si apenas va oscureciendo, los camiones pasan hasta después de las diez... ¿Estás seguro que estás bien?", "res://assets/retratos/mateo_confundido.png", VOZ_MATEO),
		HUD.linea("Antonio", "Eh... sí, sí, o sea, digo por el tráfico y eso, hoy vi algo medio raro por el rumbo y mejor prevenir, ¿va? Bueno, ahí te dejo, no te tardes tanto.", "res://assets/retratos/antonio_serio.png", VOZ_ANTONIO),
		HUD.linea("", "[i][color=#b0b5c4]La llamada se corta. Mateo se queda mirando la pantalla extrañado por el tono de su amigo.[/color][/i]", null, VOZ_NARRADOR),
		HUD.linea("Mateo", "Qué raro se puso Antonio... En fin, supongo que no pierdo nada con esperar unos minutitos más antes de irme.", "res://assets/retratos/mateo_normal.png", VOZ_MATEO),
	])
	
	HUD.mostrar_marcador(true)
