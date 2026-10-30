extends CollectibleItem
class_name Cherry

signal jogador_recuperacao(body: Node2D)

var coletado: bool = false

func _ready() -> void:
	super._ready()
	add_to_group("coletaveis")

func _on_body_entered(body: Node2D) -> void:
	if coletado:
		return
	if body.is_in_group("jogador") or body.is_in_group("player") or body is Player or body.name.to_lower() == "player" or body.name.to_lower() == "jogador":
		coletado = true
		jogador_recuperacao.emit(body)
		_collect()
