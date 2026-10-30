class_name Checkpoint
extends Area2D

# Bandeira de checkpoint: se o jogador morrer depois de tocá-la, renasce aqui.

signal ativado

const TEXTURA := preload("res://assets/misc/novos/bandeira.png")

var ativo: bool = false
var _sprite: Sprite2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2

	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURA
	_sprite.hframes = 2
	_sprite.offset = Vector2(4, -12)
	add_child(_sprite)

	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(16, 32)
	forma.shape = retangulo
	forma.position = Vector2(0, -16)
	add_child(forma)

	body_entered.connect(_on_body_entered)

func marcar_ativo() -> void:
	ativo = true
	_sprite.frame = 1

func _on_body_entered(body: Node2D) -> void:
	if ativo or not body.is_in_group("player"):
		return
	marcar_ativo()
	controladorFases.salvarCheckpoint(global_position)
	ativado.emit()
