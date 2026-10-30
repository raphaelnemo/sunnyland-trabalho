extends CharacterBody2D

signal jogadorDano(body: Node2D)

enum MovementPattern {
	VERTICAL,      # Sobe e desce (clássico do Sunny Land)
	HORIZONTAL,    # Voa da esquerda para a direita e vice-versa
	SINE_HORIZONTAL, # Voa na horizontal oscilando suavemente em onda (senoidal)
	STATIONARY     # Flutua parado no lugar com oscilação suave
}

enum State { PATROL, DIVE, RETURNING, HURT, DIE }

@export_group("Movimentação de Voo")
@export var movement_pattern: MovementPattern = MovementPattern.VERTICAL
@export var speed: float = 60.0
@export var patrol_distance: float = 80.0
@export var wave_frequency: float = 3.0 # Frequência da oscilação da onda
@export var wave_amplitude: float = 12.0 # Amplitude da oscilação da onda

@export_group("Ataque de Mergulho (Dive)")
@export var can_dive: bool = true # Se verdadeiro, mergulha no jogador ao detectá-lo
@export var dive_speed: float = 160.0
@export var return_speed: float = 80.0
@export var dive_cooldown: float = 2.0

@export_group("Combate")
@export var max_health: int = 1

var health: int
var state: State = State.PATROL
var start_position: Vector2
var direction: int = 1 # 1 para baixo / direita, -1 para cima / esquerda
var time_passed: float = 0.0
var dive_target: Vector2 = Vector2.ZERO
var can_dive_again: bool = true

@onready var anim: AnimatedSprite2D = $Anim
@onready var hit_box: HitBox = $HitBox
@onready var hurt_box: HurtBox = $HurtBox
@onready var player_detector: Area2D = $PlayerDetector

func _ready() -> void:
	# Define como corpo flutuante (voador) para não travar na física de solo/rampa
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("inimigos")
	health = max_health
	start_position = global_position

	if hurt_box:
		hurt_box.damage_received.connect(_on_damage_received)
	if hit_box:
		hit_box.hit_registered.connect(_on_hit_registered)
	if player_detector:
		player_detector.body_entered.connect(_on_player_detected)

	anim.play("fly")

func _physics_process(delta: float) -> void:
	if state == State.DIE:
		return

	time_passed += delta

	match state:
		State.PATROL:
			_process_patrol(delta)
		State.DIVE:
			_process_dive(delta)
		State.RETURNING:
			_process_returning(delta)
		State.HURT:
			velocity = Vector2.ZERO

	move_and_slide()

	# Trata colisões imediatamente após o movimento
	_handle_collisions()

func _process_patrol(delta: float) -> void:
	match movement_pattern:
		MovementPattern.VERTICAL:
			velocity.x = 0
			velocity.y = direction * speed

			# Limite de patrulha por distância
			if direction > 0 and global_position.y >= start_position.y + patrol_distance:
				direction = -1
			elif direction < 0 and global_position.y <= start_position.y - patrol_distance:
				direction = 1

			_orient_towards_nearest_player()

		MovementPattern.HORIZONTAL:
			velocity.x = direction * speed
			velocity.y = 0

			if direction > 0 and global_position.x >= start_position.x + patrol_distance:
				direction = -1
			elif direction < 0 and global_position.x <= start_position.x - patrol_distance:
				direction = 1

			anim.flip_h = direction > 0

		MovementPattern.SINE_HORIZONTAL:
			velocity.x = direction * speed
			var target_y = start_position.y + sin(time_passed * wave_frequency) * wave_amplitude
			velocity.y = (target_y - global_position.y) * 8.0

			if direction > 0 and global_position.x >= start_position.x + patrol_distance:
				direction = -1
			elif direction < 0 and global_position.x <= start_position.x - patrol_distance:
				direction = 1

			anim.flip_h = direction > 0

		MovementPattern.STATIONARY:
			var target_y = start_position.y + sin(time_passed * wave_frequency) * wave_amplitude
			velocity.x = 0
			velocity.y = (target_y - global_position.y) * 5.0
			_orient_towards_nearest_player()

func _handle_collisions() -> void:
	if state == State.PATROL:
		match movement_pattern:
			MovementPattern.VERTICAL:
				# Se estiver descendo e tocar no chão ou obstáculo abaixo, vira para cima imediatamente
				if direction > 0 and (is_on_floor() or _has_collision_below()):
					direction = -1
					velocity.y = -speed
				# Se estiver subindo e tocar no teto ou obstáculo acima, vira para baixo imediatamente
				elif direction < 0 and (is_on_ceiling() or _has_collision_above()):
					direction = 1
					velocity.y = speed

			MovementPattern.HORIZONTAL, MovementPattern.SINE_HORIZONTAL:
				# Se colidir lateralmente com uma parede, vira de direção
				if is_on_wall() or _has_collision_horizontal():
					direction *= -1
					velocity.x = direction * speed

	elif state == State.DIVE:
		# Se tocar no chão, parede ou teto durante o mergulho, cancela o mergulho e retorna
		if is_on_floor() or is_on_wall() or is_on_ceiling() or get_slide_collision_count() > 0:
			state = State.RETURNING
			velocity = Vector2.ZERO

	elif state == State.RETURNING:
		# Se bater em algo durante o retorno à base
		if is_on_ceiling() or is_on_wall() or is_on_floor():
			state = State.PATROL
			_start_dive_cooldown()

func _has_collision_below() -> bool:
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		if col.get_normal().y < -0.3:
			return true
	return false

func _has_collision_above() -> bool:
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		if col.get_normal().y > 0.3:
			return true
	return false

func _has_collision_horizontal() -> bool:
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		if abs(col.get_normal().x) > 0.5:
			return true
	return false

func _process_dive(delta: float) -> void:
	var to_target = dive_target - global_position
	var dist = to_target.length()

	if to_target.x != 0:
		anim.flip_h = to_target.x > 0

	if dist < 12.0:
		state = State.RETURNING
		velocity = Vector2.ZERO
	else:
		velocity = to_target.normalized() * dive_speed

func _process_returning(delta: float) -> void:
	var to_start = start_position - global_position
	var dist = to_start.length()

	if to_start.x != 0:
		anim.flip_h = to_start.x > 0

	if dist < 8.0:
		global_position = start_position
		velocity = Vector2.ZERO
		state = State.PATROL
		_start_dive_cooldown()
	else:
		velocity = to_start.normalized() * return_speed

func _orient_towards_nearest_player() -> void:
	var player = _get_player()
	if player:
		anim.flip_h = (player.global_position.x > global_position.x)

func _get_player() -> Node2D:
	var p = get_tree().get_first_node_in_group("player")
	if not p:
		p = get_tree().get_first_node_in_group("jogador")
	return p

func _on_player_detected(body: Node2D) -> void:
	if not can_dive or not can_dive_again:
		return
	if state != State.PATROL:
		return

	if body.is_in_group("player") or body.is_in_group("jogador"):
		dive_target = body.global_position
		state = State.DIVE
		can_dive_again = false

func _start_dive_cooldown() -> void:
	await get_tree().create_timer(dive_cooldown).timeout
	can_dive_again = true

func _on_damage_received(amount: int, knockback: Vector2) -> void:
	if state == State.DIE or state == State.HURT:
		return

	health -= amount

	if health <= 0:
		die()
	else:
		state = State.HURT
		velocity = knockback if knockback != Vector2.ZERO else Vector2.ZERO
		var tween = create_tween()
		tween.tween_property(anim, "modulate", Color(1.0, 0.2, 0.2), 0.1)
		tween.tween_property(anim, "modulate", Color.WHITE, 0.1)
		await tween.finished
		if state == State.HURT:
			state = State.PATROL

func die() -> void:
	state = State.DIE
	velocity = Vector2.ZERO

	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, false)
	if hit_box:
		hit_box.set_deferred("monitoring", false)
		hit_box.set_deferred("monitorable", false)
	if hurt_box:
		hurt_box.set_deferred("monitoring", false)
		hurt_box.set_deferred("monitorable", false)
	if player_detector:
		player_detector.set_deferred("monitoring", false)

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
