extends CharacterBody2D

signal jogadorDano(body: Node2D)

@onready var anim: AnimatedSprite2D = $Anim
@onready var hurt_box: HurtBox = $HurtBox
@onready var hit_box: HitBox = $HitBox

@export_group("Enemy Properties")
@export var speed: float = 100.0
@export var patrol_distance: float = 200.0
@export var max_health: int = 3
@export var turn_on_wall: bool = true
@export var evitar_abismo: bool = true # Vira ao chegar na beirada de uma plataforma
var sonda_abismo: Vector2 = Vector2(14.0, 28.0) # Distância à frente e para baixo do raio de abismo

enum State { IDLE, PATROL, HURT, DIE }
var state: State = State.PATROL

var health: int
@export var direction: int = -1
var turn_start_x: float = 0.0

func _ready() -> void:
	add_to_group("inimigos")
	health = max_health
	turn_start_x = global_position.x
	if hurt_box:
		hurt_box.damage_received.connect(_on_damage_received)
	if hit_box:
		hit_box.hit_registered.connect(_on_hit_registered)

	floor_snap_length = 8.0
	floor_constant_speed = true
	floor_stop_on_slope = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match state:
		State.PATROL:
			velocity.x = speed * direction
		State.HURT, State.IDLE, State.DIE:
			velocity.x = 0

	move_and_slide()

	if state == State.PATROL:
		# Vira imediatamente se colidir com uma parede na direção em que está andando
		var hit_wall := false
		if turn_on_wall and is_on_wall():
			var wall_normal := get_wall_normal()
			if (direction > 0 and wall_normal.x < -0.1) or (direction < 0 and wall_normal.x > 0.1):
				hit_wall = true
				turn()

		# Vira antes de cair de uma plataforma
		if not hit_wall and evitar_abismo and is_on_floor() and not _tem_chao_a_frente():
			hit_wall = true
			turn()

		# Vira quando atingir a quantidade de pixels andados na direção atual
		if not hit_wall:
			var distance_walked := (global_position.x - turn_start_x) * direction
			if distance_walked >= patrol_distance:
				turn()

	# Orientação do sprite (olha para a esquerda por padrão)
	anim.flip_h = direction > 0

# Lança um raio para baixo logo à frente do inimigo procurando chão
func _tem_chao_a_frente() -> bool:
	var origem := global_position + Vector2(direction * sonda_abismo.x, 0.0)
	var consulta := PhysicsRayQueryParameters2D.create(origem, origem + Vector2(0, sonda_abismo.y), 1)
	return not get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()

func turn() -> void:
	direction *= -1
	velocity.x = speed * direction
	turn_start_x = global_position.x

func _on_damage_received(amount: int, knockback: Vector2) -> void:
	# Ignora se já estiver morto ou em animação de dano (I-Frames)
	if state == State.DIE or state == State.HURT:
		return

	health -= amount

	if knockback != Vector2.ZERO:
		velocity = knockback
	velocity.y = 0

	if health <= 0:
		die()
	else:
		change_state(State.HURT)

func die() -> void:
	change_state(State.DIE)
	velocity = Vector2.ZERO

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

	# Efeito de morte com fade out
	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished
	else:
		anim.play("hurt")
		var tween = create_tween()
		tween.tween_property(anim, "modulate:a", 0.0, 0.35)
		await tween.finished

	queue_free()

func change_state(new_state: State) -> void:
	state = new_state

	match state:
		State.PATROL:
			anim.play("move")
			turn_start_x = global_position.x
		State.HURT:
			velocity.x = 0
			anim.play("hurt")
			# Pisca em vermelho no hit
			var tween = create_tween()
			tween.tween_property(anim, "modulate", Color(1.0, 0.2, 0.2), 0.1)
			tween.tween_property(anim, "modulate", Color.WHITE, 0.1)
			await get_tree().create_timer(0.3).timeout
			if state == State.HURT:
				change_state(State.PATROL)
		State.DIE:
			velocity.x = 0

func _on_hit_registered(target_hurtbox: HurtBox) -> void:
	if state == State.DIE or state == State.HURT:
		return
	var target = target_hurtbox.owner
	if target:
		jogadorDano.emit(target)
