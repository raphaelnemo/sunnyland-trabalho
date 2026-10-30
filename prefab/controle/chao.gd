extends Area2D

@onready var canvas_layer: CanvasLayer = $"../CanvasLayer"

# Lida com oque acontece com o jogador se ele cair para fora do mapa

func _on_body_entered(body : Node2D) -> void:
	if body.name == "jogador":
		canvas_layer.mostrar_morreu()
		
		await get_tree().create_timer(1.0).timeout
		
		body.resetar()
		canvas_layer.esconder_tudo()
