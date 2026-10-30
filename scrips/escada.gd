@tool
class_name Escada
extends Area2D

@export var altura: float = 64.0:
	set(valor):
		altura = maxf(16.0, valor)
		_atualizar_dimensoes()

@onready var sprite: Sprite2D = $sprite
@onready var collision: CollisionShape2D = $collision

func _ready() -> void:
	# Layer 0 (não colide como parede sólida), Mask 2 (detecta o jogador)
	collision_layer = 0
	collision_mask = 2
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
		
	_atualizar_dimensoes()

func _atualizar_dimensoes() -> void:
	if not sprite:
		sprite = get_node_or_null("sprite")
	if not collision:
		collision = get_node_or_null("collision")
		
	if sprite:
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		sprite.centered = false
		sprite.position = Vector2(-8, 0) # Centraliza em X (origem no topo centro)
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, 16, altura)
		
	if collision:
		if not collision.shape or not (collision.shape is RectangleShape2D):
			collision.shape = RectangleShape2D.new()
		elif not Engine.is_editor_hint():
			collision.shape = collision.shape.duplicate()
			
		var rect_shape: RectangleShape2D = collision.shape
		rect_shape.size = Vector2(14, altura)
		collision.position = Vector2(0, altura / 2.0)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("entrar_na_escada"):
		body.entrar_na_escada(self)

func _on_body_exited(body: Node2D) -> void:
	if body.has_method("sair_da_escada"):
		body.sair_da_escada(self)
