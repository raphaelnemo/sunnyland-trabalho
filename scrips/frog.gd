extends CharacterBody2D

signal jogadorDano(body: Node2D)

enum State { IDLE, JUMP, HURT, DIE }
var state: State = State.IDLE

@export_group("Movimentação do Sapo")
@export var speed: float = 120.0
@export var jump_force: float = -340.0
@export var jump_cooldown: float = 1.8
@export var random_jump_delay: float = 0.4
@export var turn_on_wall: bool = true
@export var avoid_cliffs: bool = false
@export var min_jumps_per_side: int = 2 # Mínimo de pulos para um lado antes de virar
@export var max_jumps_per_side: int = 3 # Máximo de pulos para um lado antes de virar
@export var track_player: bool = false # Se ativado, vira na direção do jogador antes de cada salto

@export_group("Combate")
@export var max_health: int = 2

var health: int
@export var direction: int = -1 # -1 = esquerda, 1 = direita

var jumps_in_current_direction: int = 0
var target_jumps: int = 2

@onready var anim: AnimatedSprite2D = $Anim
@onready var timer: Timer = $Timer
@onready var hit_box: HitBox = $HitBox
@onready var hurt_box: HurtBox = $HurtBox
@onready var floor_detector: RayCast2D = $FloorDetector

func _ready() -> void:
	add_to_group("inimigos")
	health = max_health
	_pick_new_target_jumps()

	if hurt_box:
		hurt_box.damage_received.connect(_on_damage_received)
	if hit_box:
		hit_box.hit_registered.connect(_on_hit_registered)

	timer.timeout.connect(_on_timer_timeout)
	_reset_timer()

	anim.play("idle")

func _physics_process(delta: float) -> void:
	if state == State.DIE:
		move_and_slide()
		return

	# Aplica gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	match state:
		State.IDLE:
			velocity.x = 0.0
			if is_on_floor() and anim.animation != "idle":
				anim.play("idle")

		State.JUMP:
			# Garante que o impulso para frente seja contínuo durante todo o pulo
			velocity.x = direction * speed

			# Animações de salto e queda conforme a velocidade vertical
			if velocity.y < 0.0:
				if anim.animation != "jump":
					anim.play("jump")
			else:
				if anim.animation != "fall":
					anim.play("fall")

			# Aterrissagem no chão (APENAS quando estiver caindo: velocity.y >= 0)
			# Isso evita que o sapo aterraterrisse no exato frame em que sai do chão
			if is_on_floor() and velocity.y >= 0.0:
				state = State.IDLE
				velocity.x = 0.0
				anim.play("idle")
				_reset_timer()

				# Contabiliza o pulo concluído nesta direção
				jumps_in_current_direction += 1
				if jumps_in_current_direction >= target_jumps:
					direction *= -1
					_pick_new_target_jumps()

		State.HURT:
			velocity.x = 0.0

	# Atualiza orientação do sprite (no SunnyLand o sprite base olha para a esquerda)
	anim.flip_h = direction > 0

	# Posiciona o sensor de abismo à frente da direção atual
	if floor_detector:
		floor_detector.position.x = direction * 14.0

	# Se bater em uma parede durante o salto ou no chão, inverte a direção e resorteia a quantidade
	if turn_on_wall and is_on_wall():
		direction *= -1
		_pick_new_target_jumps()
		if state == State.JUMP:
			velocity.x = direction * speed

	move_and_slide()

func _on_timer_timeout() -> void:
	if state != State.IDLE:
		return

	# Rastrear o jogador se a opção estiver ativada
	if track_player:
		var player = get_tree().get_first_node_in_group("player")
		if not player:
			player = get_tree().get_first_node_in_group("jogador")
		if player:
			var dir_to_player = sign(player.global_position.x - global_position.x)
			if dir_to_player != 0:
				direction = int(dir_to_player)

	# Se configurado para evitar abismo, vira antes de pular se não houver chão
	# no ponto onde o sapo vai pousar
	if avoid_cliffs and not _tem_chao_no_pouso(direction):
		direction *= -1
		_pick_new_target_jumps()
		# Se também não houver chão do outro lado, fica parado esperando
		if not _tem_chao_no_pouso(direction):
			_reset_timer()
			return

	pular()

# Calcula onde o pulo termina (tempo de voo * velocidade) e procura chão ali
func _tem_chao_no_pouso(dir: int) -> bool:
	var gravidade: float = get_gravity().y if get_gravity().y > 0.0 else 980.0
	var tempo_voo: float = 2.0 * absf(jump_force) / gravidade
	var origem := global_position + Vector2(dir * (speed * tempo_voo + 10.0), -8.0)
	var consulta := PhysicsRayQueryParameters2D.create(origem, origem + Vector2(0, 40), 1)
	return not get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()

func pular() -> void:
	state = State.JUMP
	velocity.y = jump_force
	velocity.x = direction * speed
	anim.play("jump")

func _pick_new_target_jumps() -> void:
	target_jumps = randi_range(min_jumps_per_side, max_jumps_per_side)
	jumps_in_current_direction = 0

func _reset_timer() -> void:
	var variation = randf_range(-random_jump_delay, random_jump_delay)
	timer.wait_time = max(0.5, jump_cooldown + variation)
	timer.start()

func _on_damage_received(amount: int, knockback: Vector2) -> void:
	if state == State.DIE or state == State.HURT:
		return

	health -= amount
	if health <= 0:
		die()
	else:
		state = State.HURT
		velocity.x = 0.0
		if knockback != Vector2.ZERO:
			velocity = knockback
		var tween = create_tween()
		tween.tween_property(anim, "modulate", Color(1.0, 0.2, 0.2), 0.1)
		tween.tween_property(anim, "modulate", Color.WHITE, 0.1)
		await tween.finished
		if state == State.HURT:
			state = State.IDLE
			anim.play("idle")
			_reset_timer()

func die() -> void:
	state = State.DIE
	velocity = Vector2.ZERO
	timer.stop()

	# Desativa colisões para não interferir após morrer
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, false)
	if hit_box:
		hit_box.set_deferred("monitoring", false)
		hit_box.set_deferred("monitorable", false)
	if hurt_box:
		hurt_box.set_deferred("monitoring", false)
		hurt_box.set_deferred("monitorable", false)

	# Efeito de morte do Sunny Land
	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished
	else:
		var tween = create_tween()
		tween.tween_property(anim, "modulate:a", 0.0, 0.25)
		await tween.finished

	queue_free()

func _on_hit_registered(target_hurtbox: HurtBox) -> void:
	if state == State.DIE or state == State.HURT:
		return
	var target = target_hurtbox.owner
	if target:
		jogadorDano.emit(target)
