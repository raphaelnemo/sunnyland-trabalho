class_name PlataformaCai
extends AnimatableBody2D

# Plataforma que treme e cai pouco depois de o jogador pisar nela. Volta depois de um tempo.

const TEXTURA := preload("res://assets/environment/props/small-platform.png")

var tempo_aviso: float = 0.5
var tempo_volta: float = 3.0
var cor: Color = Color.WHITE

var _origem: Vector2
var _ativada: bool = false
var _sprite: Sprite2D
var _forma: CollisionShape2D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = false
	_origem = position

	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURA
	_sprite.modulate = cor
	add_child(_sprite)

	_forma = CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(16, 8)
	_forma.shape = retangulo
	_forma.position = Vector2(0, -4)
	_forma.one_way_collision = true
	add_child(_forma)

	# Sensor logo acima da plataforma para saber quando o jogador pisou
	var sensor := Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 2
	var forma_sensor := CollisionShape2D.new()
	var retangulo_sensor := RectangleShape2D.new()
	retangulo_sensor.size = Vector2(16, 4)
	forma_sensor.shape = retangulo_sensor
	forma_sensor.position = Vector2(0, -10)
	sensor.add_child(forma_sensor)
	add_child(sensor)
	sensor.body_entered.connect(_on_pisou)

func _on_pisou(body: Node2D) -> void:
	if _ativada or not body.is_in_group("player"):
		return
	_ativada = true

	# Treme avisando que vai cair
	var tremor := create_tween()
	for i in 5:
		tremor.tween_property(_sprite, "position:x", 1.5, tempo_aviso / 10.0)
		tremor.tween_property(_sprite, "position:x", -1.5, tempo_aviso / 10.0)
	await tremor.finished
	_sprite.position.x = 0

	# Cai e some
	var queda := create_tween()
	queda.tween_property(self, "position:y", _origem.y + 160.0, 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	queda.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.8)
	await get_tree().create_timer(0.15).timeout
	_forma.set_deferred("disabled", true)
	await queda.finished

	# Reaparece no lugar original
	await get_tree().create_timer(tempo_volta).timeout
	position = _origem
	_forma.set_deferred("disabled", false)
	var volta := create_tween()
	volta.tween_property(_sprite, "modulate:a", 1.0, 0.3)
	_ativada = false
