class_name Player
extends CharacterBody2D

# ==============================================================================
# REFERÊNCIAS DE NÓS
# ==============================================================================
@onready var anim: AnimatedSprite2D = $anim
@onready var remote_transform_2d: RemoteTransform2D = $RemoteTransform2D
@onready var hit_box: HitBox = $HitBox
@onready var hurt_box: HurtBox = $HurtBox

# ==============================================================================
# FÍSICA E MOVIMENTAÇÃO (VALORES PROPORCIONAIS AO PROJETO DO GRUPO)
# ==============================================================================
@export_group("Física de Movimentação")
@export var velocidade: float = 150.0
@export var velocidade_escalada: float = 85.0
@export var forca_pulo: float = -150.0
@export var forca_pulo_sustentado: float = -230.0 # forcaPulo - 80 do Daniel
@export var tempo_pulo_max: float = 0.25
@export var tempo_coyote: float = 0.075

@export_group("Adesão ao Chão e Rampas")
@export var rampa_snap_length: float = 12.0
@export var rampa_velocidade_constante: bool = true
@export var rampa_angulo_maximo_graus: float = 50.0

# Variáveis internas de controle do pulo e escada
var pulando: bool = false
var cronometro_pulo: float = 0.0
var cronometro_coyote: float = 0.0
var controlavel: bool = true
var escada_atual: Area2D = null

# ==============================================================================
# SISTEMA DE VIDA (INTEGRADO COM AS CEREJAS E UI DO GRUPO)
# ==============================================================================
@export_group("Vida")
@export var vida_maxima: int = 3
@export var vida_atual: int = 3
var invulneravel: bool = false

# ==============================================================================
# MÁQUINA DE ESTADOS
# ==============================================================================
enum State { IDLE, RUN, JUMP, FALL, HURT, DIE, CLIMB }
var current_state: State = State.IDLE

# Cache de ações disponíveis no InputMap (evita erros de C++ a cada frame)
var _tem_input_grupo: bool = false
var _tem_input_pessoal: bool = false
var _tem_input_down: bool = false

func _ready() -> void:
	add_to_group("jogador")
	add_to_group("player")
	vida_atual = vida_maxima
	_tem_input_grupo = InputMap.has_action("irEsquerda") and InputMap.has_action("irDireita") and InputMap.has_action("pulo")
	_tem_input_pessoal = InputMap.has_action("left") and InputMap.has_action("right") and InputMap.has_action("jump")
	_tem_input_down = InputMap.has_action("down") or InputMap.has_action("baixo")
	
	# Conexão de sinais com o sistema modular de combate
	if hurt_box and not hurt_box.damage_received.is_connected(_on_damage_received):
		hurt_box.damage_received.connect(_on_damage_received)
	if hit_box and not hit_box.hit_registered.is_connected(_on_feet_hitbox_hit):
		hit_box.hit_registered.connect(_on_feet_hitbox_hit)
	
	# Vincula a câmera principal se ela existir no grupo
	if is_inside_tree() and get_tree():
		var camera = get_tree().get_first_node_in_group("main_camera")
		if camera and remote_transform_2d:
			remote_transform_2d.remote_path = camera.get_path()

	# Configuração de adesão firme a rampas/barrancos (evita quicar na descida)
	floor_snap_length = rampa_snap_length
	floor_constant_speed = rampa_velocidade_constante
	floor_max_angle = deg_to_rad(rampa_angulo_maximo_graus)
	floor_stop_on_slope = true

func _physics_process(delta: float) -> void:
	if not controlavel:
		if current_state == State.DIE:
			velocity = Vector2.ZERO
		move_and_slide()
		return

	# Queda no abismo / fora dos limites da fase
	if global_position.y > 600 and current_state != State.DIE:
		perder_vida(vida_atual)
		return

	# 0. ESCADA (CLIMBING)
	if escada_atual:
		var eixo_v := _obter_eixo_vertical()
		# Pressionar para cima ou para baixo inicia a escalada
		if current_state != State.CLIMB:
			if eixo_v < -0.2:
				current_state = State.CLIMB
			elif eixo_v > 0.2 and not is_on_floor():
				current_state = State.CLIMB

		if current_state == State.CLIMB:
			pulando = false
			cronometro_pulo = 0.0
			cronometro_coyote = 0.0

			# Pulo para soltar da escada
			if _input_acao_pressionada_agora("pulo"):
				current_state = State.JUMP
				velocity.y = forca_pulo
				var dir_pulo := _obter_eixo_horizontal()
				if dir_pulo != 0.0:
					velocity.x = dir_pulo * velocidade
				pulando = true
			else:
				velocity.y = eixo_v * velocidade_escalada
				var eixo_h := _obter_eixo_horizontal()
				if eixo_h != 0.0:
					velocity.x = eixo_h * (velocidade * 0.4)
				else:
					velocity.x = 0.0
					# Centraliza suavemente no eixo X da escada
					global_position.x = move_toward(global_position.x, escada_atual.global_position.x, 2.0)

				# Se descer até o chão, volta ao estado normal
				if is_on_floor() and eixo_v > 0.1:
					current_state = State.IDLE

				anim.play("climb")
				if eixo_v != 0.0 or eixo_h != 0.0:
					anim.speed_scale = 1.0
				else:
					anim.pause()

			move_and_slide()
			_verificar_colisao_com_espinhos()
			return

	# 1. GRAVIDADE E COYOTE TIME
	# Se estiver no chão, zera o cronômetro do coyote.
	# Enquanto o pulo sustentado estiver ativo, a gravidade é congelada (física do grupo).
	if is_on_floor():
		cronometro_coyote = 0.0
	else:
		if not pulando:
			velocity += get_gravity() * delta
			cronometro_coyote += delta

	# 2. SISTEMA DE PULO DO GRUPO (Com Coyote Time e Altura Variável)
	gerenciar_pulo(delta)

	# 3. DESCIDA DE PLATAFORMAS ONE-WAY (Sentido Único)
	if _input_acao_pressionada_agora("baixo") and is_on_floor():
		position.y += 2

	# 4. MOVIMENTAÇÃO HORIZONTAL
	var direcao := _obter_eixo_horizontal()
	if direcao != 0.0:
		velocity.x = direcao * velocidade
	else:
		# Parada responsiva idêntica ao jogador.gd
		velocity.x = move_toward(velocity.x, 0.0, velocidade)

	# 5. ATUALIZAÇÃO FÍSICA E ESTADOS
	# Executa a movimentação física primeiro para atualizar is_on_floor() no frame atual
	move_and_slide()
	update_state(direcao)
	play_state_animation()

	# Verifica colisão com tiles que possuem o dado "dano" (espinhos)
	_verificar_colisao_com_espinhos()

  
# ==============================================================================
# LÓGICA DE PULO IDÊNTICA AO JOGADOR.GD
# ==============================================================================
func gerenciar_pulo(delta: float) -> void:
	# Pulo inicial: aciona no chão ou dentro da tolerância do Coyote Time
	if _input_acao_pressionada_agora("pulo") and (is_on_floor() or cronometro_coyote < tempo_coyote):
		velocity.y = forca_pulo
		pulando = true
		cronometro_pulo = 0.0
	
	# Pulo sustentado: enquanto mantiver o botão pressionado até o tempo limite
	elif _input_acao_segurada("pulo") and pulando:
		velocity.y = forca_pulo_sustentado

	# Controle do limite de sustentação do pulo
	if pulando and _input_acao_segurada("pulo") and cronometro_pulo < tempo_pulo_max:
		cronometro_pulo += delta
	else:
		pulando = false
		cronometro_pulo = 0.0

# ==============================================================================
# GERENCIAMENTO DE ESTADOS E ANIMAÇÃO
# ==============================================================================
func update_state(direcao: float) -> void:
	if current_state == State.HURT or current_state == State.DIE or current_state == State.CLIMB:
		return

	if direcao > 0:
		anim.flip_h = false
	elif direcao < 0:
		anim.flip_h = true
		
	if not is_on_floor():
		if velocity.y < 0:
			current_state = State.JUMP
		else:
			current_state = State.FALL
	else:
		if direcao != 0:
			current_state = State.RUN
		else:
			current_state = State.IDLE

func play_state_animation() -> void:
	if not anim:
		return
		
	match current_state:
		State.IDLE:
			anim.play("idle")
		State.RUN:
			anim.play("run")
		State.JUMP:
			anim.play("jump")
		State.FALL:
			anim.play("fall")
		State.HURT:
			anim.play("hurt")
		State.DIE:
			anim.play("die")
		State.CLIMB:
			anim.play("climb")

# ==============================================================================
# CONTROLE DE ESCADA
# ==============================================================================
func entrar_na_escada(escada: Area2D) -> void:
	escada_atual = escada

func sair_da_escada(escada: Area2D) -> void:
	if escada_atual == escada:
		escada_atual = null
		if current_state == State.CLIMB:
			current_state = State.FALL

# ==============================================================================
# COMBATE E VIDA (MÉTODOS COMPATÍVEIS COM O PROJETO DO GRUPO)
# ==============================================================================
func perder_vida(quantidade: int) -> void:
	if invulneravel or current_state == State.DIE or not controlavel:
		return
	
	invulneravel = true
	vida_atual -= quantidade
	print("Jogador perdeu vida! Vida atual: ", vida_atual, "/", vida_maxima)
	
	if vida_atual <= 0:
		vida_atual = 0
		morto()
	else:
		current_state = State.HURT
		play_state_animation()
		if is_inside_tree() and get_tree():
			await get_tree().create_timer(0.4).timeout
		invulneravel = false
		if current_state == State.HURT:
			current_state = State.IDLE

func ganhar_vida(quantidade: int) -> void:
	if current_state == State.DIE:
		return
	vida_atual = mini(vida_atual + quantidade, vida_maxima)
	print("Jogador ganhou vida! Vida atual: ", vida_atual, "/", vida_maxima)

func morto() -> void:
	current_state = State.DIE
	controlavel = false
	velocity = Vector2.ZERO
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("die"):
		anim.play("die")
	if is_inside_tree() and get_tree():
		await get_tree().create_timer(1.0).timeout
	visible = false
	resetar()

func resetar() -> void:
	vida_atual = vida_maxima
	visible = true
	controlavel = true
	invulneravel = false
	current_state = State.IDLE
	
	# Se o Autoload do grupo existir, recarrega a fase pelo controlador
	if Engine.has_singleton("controladorFases") or (is_inside_tree() and get_tree() and get_tree().root.has_node("controladorFases")):
		var controlador = get_node_or_null("/root/controladorFases")
		if controlador and controlador.has_method("carregarFase"):
			controlador.carregarFase(controlador.idFaseAtual)
			return
			
	# Fallback para o seu projeto pessoal
	if is_inside_tree() and get_tree():
		get_tree().reload_current_scene()

# ==============================================================================
# SINAIS DE COMBATE (HITBOX / HURTBOX)
# ==============================================================================
func _on_damage_received(amount: int, knockback: Vector2) -> void:
	perder_vida(amount)
	if knockback != Vector2.ZERO and current_state != State.DIE:
		velocity = knockback

func _on_feet_hitbox_hit(other_hurtbox: HurtBox) -> void:
	if other_hurtbox is HurtBox:
		# Rebote ao pisar na cabeça do inimigo
		velocity.y = forca_pulo_sustentado

# ==============================================================================
# COMPATIBILIDADE DE ENTRADA (SUPORTA TANTO O SEU MAPA QUANTO O DO GRUPO)
# ==============================================================================
func _obter_eixo_horizontal() -> float:
	var eixo := 0.0
	if _tem_input_grupo:
		eixo = Input.get_axis("irEsquerda", "irDireita")
	if eixo == 0.0 and _tem_input_pessoal:
		eixo = Input.get_axis("left", "right")
	return eixo

func _obter_eixo_vertical() -> float:
	var eixo := 0.0
	if InputMap.has_action("cima") and InputMap.has_action("baixo"):
		eixo = Input.get_axis("cima", "baixo")
	if eixo == 0.0 and InputMap.has_action("up") and InputMap.has_action("down"):
		eixo = Input.get_axis("up", "down")
	return eixo

func _input_acao_pressionada_agora(acao: String) -> bool:
	match acao:
		"pulo":
			var pressionou := false
			if _tem_input_grupo:
				pressionou = Input.is_action_just_pressed("pulo")
			if not pressionou and _tem_input_pessoal:
				pressionou = Input.is_action_just_pressed("jump")
			return pressionou
		"baixo":
			var pressionou := false
			if InputMap.has_action("baixo") and Input.is_action_just_pressed("baixo"):
				pressionou = true
			elif InputMap.has_action("down") and Input.is_action_just_pressed("down"):
				pressionou = true
			return pressionou
	return false

func _input_acao_segurada(acao: String) -> bool:
	match acao:
		"pulo":
			var segurando := false
			if _tem_input_grupo:
				segurando = Input.is_action_pressed("pulo")
			if not segurando and _tem_input_pessoal:
				segurando = Input.is_action_pressed("jump")
			return segurando
	return false
	
func _verificar_colisao_com_espinhos() -> void:
	if invulneravel or current_state == State.DIE:
		return

	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		
		# Verifica se colidiu com uma camada de mapa (TileMapLayer)
		if collider is TileMapLayer:
			# Evita erro no Terrain: verifica antes se este TileSet possui a camada "dano"
			if not collider.tile_set or not collider.tile_set.has_custom_data_layer_by_name("dano"):
				continue
				
			# Entra ligeiramente na direção do tile para capturar a célula exata
			var normal: Vector2 = col.get_normal()
			var ponto_impacto: Vector2 = col.get_position() - normal * 2.0
			var tile_pos: Vector2i = collider.local_to_map(collider.to_local(ponto_impacto))
			var tile_data: TileData = _obter_tile_data_de_camada(collider, tile_pos)
			
			if tile_data and tile_data.get_custom_data("dano"):
				perder_vida(1)
				pulando = false
				cronometro_pulo = tempo_pulo_max
				
				# Knockback inteligente de acordo com a direção do espinho:
				if normal.y > 0.5:
					# Bateu de cabeça no teto: empurra o jogador para baixo
					velocity.y = abs(forca_pulo) * 0.8
				elif normal.y < -0.5:
					# Pisou no chão: empurra o jogador para cima (knockup clássico)
					velocity.y = forca_pulo
				elif abs(normal.x) > 0.5:
					# Bateu de lado em espinho de parede: empurra horizontalmente e um pouco para cima
					velocity.x = normal.x * velocidade
					velocity.y = forca_pulo * 0.6
				else:
					velocity = normal * abs(forca_pulo)
				break

func _obter_tile_data_de_camada(layer: TileMapLayer, celula: Vector2i) -> TileData:
	# 1. Se a célula direta possui TileData (tiles 1x1 ou célula raiz do multi-tile)
	var td: TileData = layer.get_cell_tile_data(celula)
	if td:
		return td
	
	# 2. Se for parte de um multi-tile (ex: espinho com tamanho 2x2 no atlas)
	# Procura a célula de origem nos arredores da colisão
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			if dx == 0 and dy == 0:
				continue
			var candidato := celula + Vector2i(dx, dy)
			var candidato_td: TileData = layer.get_cell_tile_data(candidato)
			if candidato_td:
				var src_id: int = layer.get_cell_source_id(candidato)
				if layer.tile_set.has_source(src_id):
					var src: TileSetSource = layer.tile_set.get_source(src_id)
					if src is TileSetAtlasSource:
						var atlas_coords: Vector2i = layer.get_cell_atlas_coords(candidato)
						var tam: Vector2i = src.get_tile_size_in_atlas(atlas_coords)
						if celula.x >= candidato.x and celula.x < candidato.x + tam.x \
						and celula.y >= candidato.y and celula.y < candidato.y + tam.y:
							return candidato_td
	return null
