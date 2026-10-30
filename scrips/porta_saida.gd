class_name PortaSaida
extends Area2D

## Cena para a qual o jogo deve ir ao concluir a fase (opcional)
@export_file("*.tscn") var proxima_fase: String = ""

var jogador_na_porta: bool = false
var jogador_ref: Player = null
var fase_concluida: bool = false

@onready var prompt_label: Label = get_node_or_null("PromptLabel")
var _prompt_base_y: float = -32.0
var _prompt_tween: Tween = null

func _ready() -> void:
	z_index = 30
	z_as_relative = false
	
	# Layer 0 (não é parede física), Mask 2 e 1 (detecta o jogador com certeza)
	collision_layer = 0
	collision_mask = 2
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
		
	if prompt_label:
		prompt_label.z_index = 35
		prompt_label.z_as_relative = false
		_prompt_base_y = prompt_label.position.y
		prompt_label.visible = false
		prompt_label.modulate.a = 1.0
		
	# Checa se o jogador já começou dentro da área
	call_deferred("_checar_corpos_iniciais")

func _checar_corpos_iniciais() -> void:
	for body in get_overlapping_bodies():
		_on_body_entered(body)

func _on_body_entered(body: Node2D) -> void:
	if body is Player or body.is_in_group("player") or body.is_in_group("jogador") or body.name == "Player":
		print("[Porta] Jogador chegou na porta!")
		jogador_na_porta = true
		if body is Player:
			jogador_ref = body as Player
		elif body is CharacterBody2D:
			jogador_ref = body as Player
		if prompt_label:
			prompt_label.visible = true
			prompt_label.modulate.a = 1.0

func _on_body_exited(body: Node2D) -> void:
	if body is Player or body.is_in_group("player") or body.is_in_group("jogador") or body.name == "Player":
		print("[Porta] Jogador saiu da porta.")
		jogador_na_porta = false
		jogador_ref = null
		if prompt_label:
			prompt_label.visible = false

func _process(_delta: float) -> void:
	if fase_concluida:
		return
		
	# Efeito de flutuação suave do texto "▲ Entrar"
	if prompt_label and prompt_label.visible:
		prompt_label.position.y = _prompt_base_y + sin(Time.get_ticks_msec() * 0.006) * 2.5
		
	if jogador_na_porta and _checar_input_cima():
		concluir_fase()

func _checar_input_cima() -> bool:
	return (
		Input.is_action_just_pressed("up")
		or Input.is_action_just_pressed("ui_up")
		or (InputMap.has_action("cima") and Input.is_action_just_pressed("cima"))
	)

func concluir_fase() -> void:
	fase_concluida = true
	
	if prompt_label:
		prompt_label.visible = false
		
	# Trava o jogador e faz ele entrar na casa (fade out)
	if jogador_ref:
		jogador_ref.controlavel = false
		jogador_ref.velocity = Vector2.ZERO
		if jogador_ref.anim:
			jogador_ref.anim.play("idle")
		
		var tween := create_tween()
		tween.tween_property(jogador_ref, "modulate:a", 0.0, 0.4)
		await tween.finished
	
	await get_tree().create_timer(0.3).timeout
	
	# Atualiza o controlador de fases se ele estiver ativo no grupo
	if Engine.has_singleton("controladorFases") or (is_inside_tree() and get_tree() and get_tree().root.has_node("controladorFases")):
		var controlador = get_node_or_null("/root/controladorFases")
		if controlador and controlador.has_method("faseCompletada"):
			controlador.faseCompletada(5)
			controlador.desbloquearFase(5)

	# Se configurou uma próxima fase no Inspetor, carrega ela
	if proxima_fase != "":
		get_tree().change_scene_to_file(proxima_fase)
		return
		
	# Caso contrário, exibe uma tela de vitória elegante
	_exibir_tela_vitoria()

func _exibir_tela_vitoria() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "TelaVitoria"
	canvas.layer = 100
	
	# Fundo semi-transparente escurecido
	var fundo := ColorRect.new()
	fundo.color = Color(0.0, 0.0, 0.0, 0.65)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fundo)
	
	# Container centralizado
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.theme_override_constants.separation = 8
	fundo.add_child(vbox)
	
	# Título de vitória
	var titulo := Label.new()
	titulo.text = "★ FASE 05 CONCLUÍDA! ★"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.theme_override_colors.font_color = Color(1.0, 0.84, 0.0) # Dourado
	titulo.theme_override_font_sizes.font_size = 18
	vbox.add_child(titulo)
	
	# Subtítulo
	var subtitulo := Label.new()
	subtitulo.text = "Parabéns, você chegou até o fim!"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.theme_override_font_sizes.font_size = 11
	vbox.add_child(subtitulo)
	
	# Espaçador
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(sep)
	
	# Botão de reiniciar fase
	var botao_reiniciar := Button.new()
	botao_reiniciar.text = "Jogar Novamente"
	botao_reiniciar.theme_override_font_sizes.font_size = 11
	botao_reiniciar.pressed.connect(func():
		canvas.queue_free()
		var controlador = get_node_or_null("/root/controladorFases")
		if controlador and controlador.has_method("carregarFase") and controlador.idFaseAtual > 0:
			controlador.carregarFase(controlador.idFaseAtual)
		else:
			get_tree().reload_current_scene()
	)
	vbox.add_child(botao_reiniciar)

	# Botão de voltar ao seletor de fases
	var botao_seletor := Button.new()
	botao_seletor.text = "Menu de Fases"
	botao_seletor.theme_override_font_sizes.font_size = 11
	botao_seletor.pressed.connect(func():
		canvas.queue_free()
		var controlador = get_node_or_null("/root/controladorFases")
		if controlador and controlador.has_method("carregarFase"):
			controlador.fecharfase()
			controlador.carregarFase(0)
		else:
			get_tree().change_scene_to_file("res://principal.tscn")
	)
	vbox.add_child(botao_seletor)
	
	get_tree().root.add_child(canvas)
	botao_reiniciar.grab_focus()
