extends Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var player: CharacterBody2D

signal jogadorDano

const velocidade = 40.0
var direcao := -1

func _physics_process(delta):
	position.x += direcao * velocidade * delta

func _on_timer_timeout() -> void:
	direcao *= -1
	animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h


func _on_body_entered(body: Node2D) -> void:
	if body.name == "jogador":
		var y_delta = position.y - body.position.y
		if (y_delta > -99):
			print("enemy dies", y_delta)
			queue_free()
		if (y_delta < -100):
			print("hit", y_delta)
			emit_signal("jogadorDano",body) 
