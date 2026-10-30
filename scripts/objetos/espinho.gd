class_name Espinho
extends Area2D

# Espinhos: machucam o jogador enquanto ele estiver encostado e o jogam para cima.

const TEXTURA := preload("res://assets/environment/props/spikes.png")

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2

	var sprite := Sprite2D.new()
	sprite.texture = TEXTURA
	sprite.offset = Vector2(0, -TEXTURA.get_height() / 2.0)
	add_child(sprite)

	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(12, 6)
	forma.shape = retangulo
	forma.position = Vector2(0, -3)
	add_child(forma)

func _physics_process(_delta: float) -> void:
	for corpo in get_overlapping_bodies():
		if corpo is Player and not corpo.invulneravel and corpo.controlavel:
			corpo.perder_vida(1)
			corpo.velocity.y = -260.0
			corpo.pulando = false
