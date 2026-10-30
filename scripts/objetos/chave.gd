class_name Chave
extends Area2D

# Chave coletável. A fase precisa de todas as chaves para destrancar a porta de saída.

signal chave_coletada(chave: Chave)

const TEXTURA := preload("res://assets/misc/novos/chave.png")
const FEEDBACK := preload("res://prefab/coletaveis/Feedback/feedback.tscn")

var idChave: int = 0
var coletada: bool = false
var _sprite: Sprite2D
var _tempo: float = 0.0

func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	add_to_group("chaves")

	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURA
	add_child(_sprite)

	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 8.0
	forma.shape = circulo
	add_child(forma)

	# Brilho em volta da chave para ela chamar atenção (aparece mesmo nas fases escuras)
	var luz := PointLight2D.new()
	luz.texture = ConstrutorFase.textura_luz()
	luz.texture_scale = 0.6
	luz.energy = 0.8
	luz.color = Color(1.0, 0.85, 0.4)
	add_child(luz)

	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Flutua e "gira" (achata no eixo X) para parecer uma chave mágica
	_tempo += delta
	_sprite.position.y = sin(_tempo * 3.0) * 2.0
	_sprite.scale.x = cos(_tempo * 2.5)

func _on_body_entered(body: Node2D) -> void:
	if coletada or not body.is_in_group("player"):
		return
	coletada = true
	var feedback := FEEDBACK.instantiate()
	get_parent().add_child(feedback)
	feedback.global_position = global_position
	chave_coletada.emit(self)
	queue_free()
