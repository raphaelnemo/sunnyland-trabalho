extends Node

# Teste automático (não faz parte do jogo): carrega cada fase, tira prints,
# leva o jogador até cada chave e até a porta, e confere se a fase foi concluída.
# Rodar: Godot --path . res://tools/teste.tscn -- <pasta_de_saida>

var saida := "user://teste"

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		saida = args[0]
	DirAccess.make_dir_recursive_absolute(saida)
	var principal: Node = load("res://principal.tscn").instantiate()
	get_tree().root.add_child.call_deferred(principal)
	await get_tree().process_frame
	await get_tree().process_frame
	principal.get_node("Menu").desativar()
	for nivel in controladorFases.fasesDisponiveis:
		nivel.faseDesbloqueada = true

	controladorFases.carregarFase(0)
	await _esperar(30)
	await _print("seletor")

	var falhas := 0
	for id in range(1, 6):
		controladorFases.iniciarFase(id)
		await _esperar(20)
		var f: ConstrutorFase = controladorFases.faseCarregada
		print("FASE %d: %dx%d celulas, chaves=%d, inimigos=%d, diamantes=%d" % [id, f.largura, f.altura, f.total_chaves, f._mundo.get_node("Inimigos").get_child_count(), get_tree().get_nodes_in_group("diamantes").size()])
		await _esperar(50)
		await _print("fase%d_inicio" % id)
		await _visao_geral(f, "fase%d_mapa" % id)

		# Mata o chefe (se tiver) para a chave dele aparecer
		if is_instance_valid(f.chefe):
			f.chefe.die()
			await _esperar(60)

		# Pega todas as chaves
		for chave in get_tree().get_nodes_in_group("chaves"):
			if is_instance_valid(chave):
				f.jogador.global_position = chave.global_position
				f.jogador.velocity = Vector2.ZERO
				await _esperar(4)
		await _esperar(10)
		print("  chaves coletadas %d/%d, porta trancada=%s" % [f.chaves_coletadas, f.total_chaves, f.porta.trancada])
		if id == 3:
			await _print("fase3_com_chaves")

		# Vai até a porta e aperta para cima
		f.jogador.global_position = f.porta.global_position + Vector2(0, -16)
		await _esperar(6)
		Input.action_press("up")
		await _esperar(2)
		Input.action_release("up")
		await _esperar(60)
		var ok := controladorFases.estaCompletada(id) and (id == 5 or controladorFases.estaDesbloqueada(id + 1))
		print("  fase %d concluida: %s" % [id, ok])
		if not ok:
			falhas += 1
		await _print("fase%d_fim" % id)

	print("RESULTADO: %s" % ("OK" if falhas == 0 else "%d FALHAS" % falhas))
	get_tree().quit()

func _esperar(quadros: int) -> void:
	for i in quadros:
		await get_tree().physics_frame

func _print(nome: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [saida, nome])

# Afasta a câmera para mostrar o mapa inteiro
func _visao_geral(f: ConstrutorFase, nome: String) -> void:
	var cam := f.camera
	var remoto := f.jogador.remote_transform_2d
	remoto.remote_path = NodePath("")
	var tamanho := Vector2(f.largura * 16, f.altura * 16)
	var zoom := minf(get_viewport().get_visible_rect().size.x / tamanho.x, get_viewport().get_visible_rect().size.y / tamanho.y)
	cam.limit_left = -100000
	cam.limit_top = -100000
	cam.limit_right = 100000
	cam.limit_bottom = 100000
	cam.zoom = Vector2(zoom, zoom)
	cam.position_smoothing_enabled = false
	cam.global_position = tamanho / 2.0
	await _esperar(3)
	await _print(nome)
	cam.zoom = Vector2.ONE
	remoto.remote_path = remoto.get_path_to(cam)
