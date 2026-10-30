class_name ZonaMorte
extends Area2D

# Área que mata o jogador na hora (água do pântano, lava, queda no abismo).

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and body.current_state != Player.State.DIE:
		body.invulneravel = false
		body.perder_vida(body.vida_atual)
