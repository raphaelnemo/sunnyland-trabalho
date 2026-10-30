extends "res://scrips/opossum.gd"

# Chefe da fase final: um gambá gigante. Patrulha a arena e, de tempos em tempos,
# pisca e faz uma investida rápida na direção do jogador. Com metade da vida fica
# furioso (mais rápido e investe com mais frequência). Ao morrer libera uma chave.

signal vida_mudou(atual: int, maximo: int)
signal derrotado(posicao: Vector2)

@export var velocidade_investida: float = 170.0
@export var intervalo_investida: float = 2.6
@export var duracao_investida: float = 1.1

var _velocidade_base: float = 0.0
var _cronometro: float = 0.0
var _investindo: bool = false
var _preparando: bool = false
var _furioso: bool = false

func _ready() -> void:
	super._ready()
	_velocidade_base = speed
	patrol_distance = 100000.0

func _physics_process(delta: float) -> void:
	if state == State.PATROL and not _investindo and not _preparando:
		_cronometro += delta
		if _cronometro >= intervalo_investida:
			_preparar_investida()
	super._physics_process(delta)

func _preparar_investida() -> void:
	_preparando = true
	_cronometro = 0.0
	state = State.IDLE
	var piscar := create_tween()
	for i in 3:
		piscar.tween_property(anim, "modulate", Color(1.0, 1.0, 0.3), 0.08)
		piscar.tween_property(anim, "modulate", Color.WHITE, 0.08)
	await piscar.finished
	_preparando = false
	if state != State.IDLE:
		return

	var jogador := get_tree().get_first_node_in_group("player") as Node2D
	if jogador:
		var lado := signi(int(jogador.global_position.x - global_position.x))
		if lado != 0:
			direction = lado
	speed = velocidade_investida * (1.3 if _furioso else 1.0)
	_investindo = true
	change_state(State.PATROL)
	await get_tree().create_timer(duracao_investida).timeout
	_investindo = false
	speed = _velocidade_base * (1.5 if _furioso else 1.0)

func _on_damage_received(amount: int, knockback: Vector2) -> void:
	if state == State.DIE or state == State.HURT:
		return
	super._on_damage_received(amount, knockback)
	vida_mudou.emit(maxi(health, 0), max_health)
	if not _furioso and health > 0 and health <= max_health / 2:
		_furioso = true
		intervalo_investida *= 0.6
		speed = _velocidade_base * 1.5
		anim.self_modulate = Color(1.0, 0.55, 0.55)

func die() -> void:
	derrotado.emit(global_position)
	super.die()
