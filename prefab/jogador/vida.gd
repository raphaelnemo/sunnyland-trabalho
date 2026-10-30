extends Node


@onready var jogador: CharacterBody2D = $jogador
@onready var lista_pontos : Array = [
$Ui/vida/HBoxContainer/ponto1,
$Ui/vida/HBoxContainer/ponto2,
$Ui/vida/HBoxContainer/ponto3
]

var vida_anterior : int = -1

# ----- Bloco _physics_process - Atualia a todo frame -----
func _process(_delta: float) -> void:
	
	# Se o jogador não existir na cena, tenta achar ele
	if not is_instance_valid(jogador):
		
		# Tenta buscar pelo grupo ou caminho caso ele mude de cena
		jogador = get_tree().get_first_node_in_group("jogador")
		if not jogador:
			return
	
	# Monitora se a vida atual mudou para esconder/mostrar as ponto/cereja preenchidos
	if jogador.vida_atual != vida_anterior:
		vida_anterior = jogador.vida_atual
		atualizar_vida_ui(vida_anterior)
# ----- Bloco _physics_process - Atualia a todo frame -----

# Função que atualiza o quanto de vida é mostrada na Ui
func atualizar_vida_ui(vida_atual: int) -> void:
	for i in range(lista_pontos.size()):
		if i < vida_atual:
			lista_pontos[i].visible = true  # ponto/cereja cheio/visível
		else:
			lista_pontos[i].visible = false # ponto/cereja vazio/escondido

# função que recebe e repassa o sinal de dano
func _on_gamba_jogador_dano(body) -> void:
	if body.name == "jogador":
		body.perder_vida(1)

# função que recebe e repassa o sinal de recuperacao
func _on_cereja_jogador_recuperacao(body) -> void:
	if body.name == "jogador":
		body.ganhar_vida(1)
