extends Node

var jogador: CharacterBody2D = null

var lista_pontos: Array:
	get:
		if _lista_pontos.is_empty() or _lista_pontos.has(null):
			_lista_pontos = [
				get_node_or_null("Ui/vida/HBoxContainer/ponto1"),
				get_node_or_null("Ui/vida/HBoxContainer/ponto2"),
				get_node_or_null("Ui/vida/HBoxContainer/ponto3")
			]
		return _lista_pontos
	set(val):
		_lista_pontos = val

var _lista_pontos: Array = []
var vida_anterior: int = -1

@export var cor_ativa: Color = Color.WHITE
@export var cor_perdida: Color = Color(0.25, 0.25, 0.25, 0.6)

func _ready() -> void:
	_buscar_jogador()
	var _p = lista_pontos
	_conectar_sinais_automaticos()
	if is_inside_tree() and get_tree():
		get_tree().node_added.connect(_on_node_added)

func _buscar_jogador() -> void:
	if has_node("jogador"):
		jogador = get_node("jogador")
	elif get_parent() and get_parent().has_node("Player"):
		jogador = get_parent().get_node("Player")
	elif is_inside_tree() and get_tree():
		if is_instance_valid(get_tree().get_first_node_in_group("jogador")):
			jogador = get_tree().get_first_node_in_group("jogador")
		elif is_instance_valid(get_tree().get_first_node_in_group("player")):
			jogador = get_tree().get_first_node_in_group("player")

# ----- Bloco _process - Atualiza a todo frame -----
func _process(_delta: float) -> void:
	# Se o jogador não existir na cena, tenta achar ele
	if not is_instance_valid(jogador):
		_buscar_jogador()
		if not is_instance_valid(jogador):
			return
	
	# Monitora se a vida atual mudou para esconder/mostrar as ponto/cereja preenchidos
	if jogador.vida_atual != vida_anterior:
		vida_anterior = jogador.vida_atual
		atualizar_vida_ui(vida_anterior)
# ----- Bloco _process - Atualiza a todo frame -----

# Função que atualiza o quanto de vida é mostrada na Ui
func atualizar_vida_ui(vida_atual: int) -> void:
	for i in range(lista_pontos.size()):
		if i < lista_pontos.size() and lista_pontos[i] and is_instance_valid(lista_pontos[i]):
			lista_pontos[i].visible = true
			if i < vida_atual:
				lista_pontos[i].modulate = cor_ativa
			else:
				lista_pontos[i].modulate = cor_perdida

# função que recebe e repassa o sinal de dano
func _on_gamba_jogador_dano(body = null) -> void:
	var alvo = body if body != null else jogador
	if alvo == null:
		_buscar_jogador()
		alvo = jogador
	if alvo and alvo.has_method("perder_vida"):
		alvo.perder_vida(1)

# função que recebe e repassa o sinal de recuperacao
func _on_cereja_jogador_recuperacao(body = null) -> void:
	var alvo = body if body != null else jogador
	if alvo == null:
		_buscar_jogador()
		alvo = jogador
	if alvo and alvo.has_method("ganhar_vida"):
		alvo.ganhar_vida(1)

func _conectar_sinais_automaticos() -> void:
	if not is_inside_tree() or get_tree() == null:
		return
	for node in get_tree().get_nodes_in_group("inimigos"):
		_conectar_se_possuir_sinal(node)
	for node in get_tree().get_nodes_in_group("coletaveis"):
		_conectar_se_possuir_sinal(node)

func _on_node_added(node: Node) -> void:
	_conectar_se_possuir_sinal(node)

func _conectar_se_possuir_sinal(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node.has_signal("jogadorDano") and not node.jogadorDano.is_connected(_on_gamba_jogador_dano):
		node.jogadorDano.connect(_on_gamba_jogador_dano)
	if node.has_signal("jogador_recuperacao") and not node.jogador_recuperacao.is_connected(_on_cereja_jogador_recuperacao):
		node.jogador_recuperacao.connect(_on_cereja_jogador_recuperacao)
