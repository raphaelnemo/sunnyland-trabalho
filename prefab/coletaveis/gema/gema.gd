extends Area2D

# Carrega o feedback em uma variavel
@onready var feedback = preload("res://prefab/coletaveis/Feedback/feedback.tscn") 

# Funçao que aciona o feedback de item coletado
func spawn_feedback():
	# Atribui uma instancia do feedback a uma variavel
	var intancia_feedback = feedback.instantiate()
	# Coloca essa instancia na sena atual
	get_tree().current_scene.add_child(intancia_feedback)
	# Coloca a instancia do feedback na mesma posição que a cereja
	intancia_feedback.global_position = global_position

# Quando o jogador coleta a cereja o feedback e o sinal são ativados e a cereja é destruida 
func _on_body_entered(body: Node2D) -> void:
	if body.name == "jogador":
		spawn_feedback()
		queue_free()
