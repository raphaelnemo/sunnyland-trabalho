# Componentes
class_name HitBox 
extends Area2D

signal hit_registered (hurtbox: HurtBox)

@export var damage: int = 1
@export var knockback_force: float = 500.0
@export var knockback_upward: float = 200.0

func _ready() -> void:
	self.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is HurtBox:
		# Não permite que o personagem atinja a si mesmo
		var meu_dono = owner if owner else get_parent()
		var outro_dono = area.owner if area.owner else area.get_parent()
		if meu_dono == outro_dono:
			return

		# Evita fogo amigo entre inimigos
		if meu_dono and outro_dono:
			if meu_dono.is_in_group("inimigos") and outro_dono.is_in_group("inimigos"):
				return

		var direction: float = sign(area.global_position.x - global_position.x)

		if direction == 0:
			direction = 1.0
			
		var final_knockback: Vector2 = Vector2(direction * knockback_force, -knockback_upward)
		area.take_damage(damage, final_knockback)
		hit_registered.emit(area)
