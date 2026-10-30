extends Node

const GemScript = preload("res://scrips/gem.gd")

@export var total_diamantes: int = 0
@export var diamantes_coletados: int = 0

@onready var label_pontuacao: Label = get_node_or_null("Ui/pontuacao/HBoxContainer/LabelPontuacao")

func _ready() -> void:
	add_to_group("controlador_pontos")
	
	if is_inside_tree() and get_tree():
		get_tree().node_added.connect(_on_node_added)
	
	# Aguarda frame para garantir que toda a árvore da fase esteja instanciada
	await get_tree().process_frame
	_inicializar_contagem()

func _inicializar_contagem() -> void:
	if not is_inside_tree() or get_tree() == null:
		return
	
	if total_diamantes <= 0:
		var diamantes = get_tree().get_nodes_in_group("diamantes")
		if diamantes.is_empty():
			# Fallback: procura por instâncias de Gem ou com nome Gem nos coletáveis
			for node in get_tree().get_nodes_in_group("coletaveis"):
				if (node is GemScript) or node.name.begins_with("Gem"):
					node.add_to_group("diamantes")
			diamantes = get_tree().get_nodes_in_group("diamantes")
		
		# Fallback adicional: varre o container Items se existir
		if diamantes.is_empty():
			var items_node = get_tree().current_scene.find_child("Items", true, false)
			if items_node:
				for child in items_node.get_children():
					if (child is GemScript) or child.name.begins_with("Gem"):
						child.add_to_group("diamantes")
				diamantes = get_tree().get_nodes_in_group("diamantes")
				
		total_diamantes = diamantes.size()
	
	# Conecta os sinais dos diamantes existentes
	for diamante in get_tree().get_nodes_in_group("diamantes"):
		_conectar_diamante(diamante)
		
	atualizar_ui()
	print("HUD Diamantes carregado com sucesso! Total na fase: ", total_diamantes)

func _on_node_added(node: Node) -> void:
	if node.is_in_group("diamantes") or (node is GemScript) or node.name.begins_with("Gem"):
		if not node.is_in_group("diamantes"):
			node.add_to_group("diamantes")
		_conectar_diamante(node)

func _conectar_diamante(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node.has_signal("diamante_coletado") and not node.diamante_coletado.is_connected(_on_diamante_coletado):
		node.diamante_coletado.connect(_on_diamante_coletado)

func _on_diamante_coletado(_valor: int = 1) -> void:
	diamantes_coletados += 1
	atualizar_ui()
	print("Diamante coletado: %02d/%02d" % [diamantes_coletados, total_diamantes])

func registrar_diamante_coletado(qtd: int = 1) -> void:
	diamantes_coletados += qtd
	atualizar_ui()

func atualizar_ui() -> void:
	if not is_instance_valid(label_pontuacao):
		label_pontuacao = get_node_or_null("Ui/pontuacao/HBoxContainer/LabelPontuacao")
	
	if label_pontuacao:
		label_pontuacao.text = "%02d/%02d" % [diamantes_coletados, total_diamantes]
