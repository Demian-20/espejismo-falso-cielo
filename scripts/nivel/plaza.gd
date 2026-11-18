extends Node2D
## Escena de la Plaza Zaragoza. Cambia el ambiente sonoro según la etapa del prólogo:
## tarde, noche y persecución. El issue #9 solo tiene que cambiar GameState.etapa_prologo.


func _ready() -> void:
	GameState.etapa_cambio.connect(_al_cambiar_etapa)
	_al_cambiar_etapa(GameState.etapa_prologo)


func _al_cambiar_etapa(etapa: int) -> void:
	if etapa == GameState.Etapa.NOCHE:
		Audio.musica("plaza_noche")
	elif etapa == GameState.Etapa.PERSECUCION:
		Audio.musica("tension")
	else:
		Audio.musica("plaza_tarde")
