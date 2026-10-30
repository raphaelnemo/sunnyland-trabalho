extends Area2D

@onready var canvas_layer: CanvasLayer = $"../CanvasLayer"

# Define a ordem das funções que lidam com a fase sendo completada

func _on_body_entered(body: Node2D) -> void:
	if body.name == "jogador":
		canvas_layer.mostrar_ganhou()
		body.controlavel = false
		
		controladorFases.faseCompletada(controladorFases.idFaseAtual)
		controladorFases.desbloquearFase(controladorFases.idFaseAtual + 1)
		
		await get_tree().create_timer(1.0).timeout
		
		controladorFases.fecharfase()
		controladorFases.carregarFase(0)
