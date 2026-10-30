extends CollectibleItem
class_name Gem

signal diamante_coletado(pontos: int)

var coletado: bool = false

func _ready() -> void:
	super._ready()
	add_to_group("diamantes")
	add_to_group("coletaveis")

func _on_body_entered(body: Node2D) -> void:
	if coletado:
		return
	if body.is_in_group("jogador") or body.is_in_group("player") or body is Player or body.name.to_lower() == "player" or body.name.to_lower() == "jogador":
		coletado = true
		diamante_coletado.emit(score_value)
		_collect()

func _collect() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	super._collect()
