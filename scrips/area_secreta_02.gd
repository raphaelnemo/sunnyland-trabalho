extends Area2D

@export var duracao_transicao: float = 0.6

@onready var polygon_2d: Polygon2D = $Polygon2D
var _tween: Tween

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if polygon_2d:
		polygon_2d.modulate.a = 1.0

func _on_body_entered(body: Node2D) -> void:
	if body is Player or body.is_in_group("player"):
		_transicionar_opacidade(0.0)

func _on_body_exited(body: Node2D) -> void:
	if body is Player or body.is_in_group("player"):
		_transicionar_opacidade(1.0)

func _transicionar_opacidade(alvo_alpha: float) -> void:
	if not polygon_2d:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(polygon_2d, "modulate:a", alvo_alpha, duracao_transicao)
