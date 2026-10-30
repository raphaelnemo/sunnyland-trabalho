extends Node

# Teste de física (não faz parte do jogo): altura do pulo, escada, inimigos
# que não caem das plataformas, plataforma que cai e o chefe.

func _ready() -> void:
	var principal: Node = load("res://principal.tscn").instantiate()
	get_tree().root.add_child.call_deferred(principal)
	await get_tree().process_frame
	await get_tree().process_frame
	principal.get_node("Menu").desativar()
	for nivel in controladorFases.fasesDisponiveis:
		nivel.faseDesbloqueada = true

	# 1) Altura e distância máximas do pulo
	controladorFases.iniciarFase(1)
	await _esperar(30)
	var f: ConstrutorFase = controladorFases.faseCarregada
	var j := f.jogador
	var y0 := j.global_position.y
	var x0 := j.global_position.x
	Input.action_press("pulo")
	Input.action_press("irDireita")
	var menor_y := y0
	for i in 120:
		await get_tree().physics_frame
		menor_y = minf(menor_y, j.global_position.y)
		if i > 5 and j.is_on_floor():
			break
	Input.action_release("pulo")
	Input.action_release("irDireita")
	print("PULO: altura max = %.1f px (%.1f tiles), distancia = %.1f px" % [y0 - menor_y, (y0 - menor_y) / 16.0, j.global_position.x - x0])

	# 2) Escada (fase 3): sobe da base até o topo
	controladorFases.iniciarFase(3)
	await _esperar(30)
	f = controladorFases.faseCarregada
	j = f.jogador
	var escada: Escada = null
	for no in f._mundo.get_node("Itens").get_children():
		if no is Escada:
			escada = no
			break
	j.global_position = Vector2(escada.global_position.x, escada.global_position.y + escada.altura - 16)
	await _esperar(10)
	Input.action_press("up")
	await _esperar(150)
	Input.action_release("up")
	await _esperar(30)
	print("ESCADA: topo y=%.0f, jogador pe y=%.0f, no chao=%s" % [escada.global_position.y + 8, j.global_position.y + 16, j.is_on_floor()])

	# 3) Inimigos ficam nas plataformas (simula 15s em cada fase)
	for id in range(1, 6):
		controladorFases.iniciarFase(id)
		await _esperar(10)
		f = controladorFases.faseCarregada
		f.jogador.global_position = Vector2(8, -2000) # tira o jogador do caminho
		f.jogador.controlavel = false
		var inimigos := f._mundo.get_node("Inimigos")
		var antes := inimigos.get_child_count()
		await _esperar(900)
		var caiu := 0
		for inimigo in inimigos.get_children():
			if inimigo.global_position.y > f.altura * 16:
				caiu += 1
		print("INIMIGOS fase %d: %d no inicio, %d vivos, %d cairam" % [id, antes, inimigos.get_child_count(), caiu])

	# 4) Plataforma que cai (fase 4)
	controladorFases.iniciarFase(4)
	await _esperar(10)
	f = controladorFases.faseCarregada
	var cai: PlataformaCai = null
	for no in f._mundo.get_node("Itens").get_children():
		if no is PlataformaCai:
			cai = no
			break
	var origem := cai.global_position
	f.jogador.global_position = cai.global_position + Vector2(0, -30)
	await _esperar(90)
	print("PLATAFORMA CAI: desceu %.0f px" % (cai.global_position.y - origem.y))

	# 5) Chefe: leva pisões até morrer e solta a chave
	controladorFases.iniciarFase(5)
	await _esperar(10)
	f = controladorFases.faseCarregada
	var chefe := f.chefe
	var x_inicial := chefe.global_position.x
	f.jogador.global_position = chefe.global_position + Vector2(-150, 0)
	await _esperar(240)
	print("CHEFE: se moveu %.0f px, vida %d/%d" % [absf(chefe.global_position.x - x_inicial), chefe.health, chefe.max_health])
	var golpes := 0
	while is_instance_valid(chefe) and chefe.health > 0 and golpes < 20:
		chefe.hurt_box.take_damage(1, Vector2.ZERO)
		golpes += 1
		await _esperar(25)
	await _esperar(60)
	print("CHEFE: derrotado com %d golpes, chaves na fase = %d" % [golpes, get_tree().get_nodes_in_group("chaves").size()])
	get_tree().quit()

func _esperar(quadros: int) -> void:
	for i in quadros:
		await get_tree().physics_frame
