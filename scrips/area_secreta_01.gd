extends Area2D

@export var duracao_transicao: float = 1.2
@export var limite_caverna: int = -400

var _limite_original: int = 0
var _limite_definido: bool = false
var _tween: Tween

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _obter_camera() -> Camera2D:
	return get_tree().get_first_node_in_group("main_camera") as Camera2D

func _on_body_entered(body: Node2D) -> void:
	if body is Player or body.is_in_group("player"):
		var camera := _obter_camera()
		if camera and not _limite_definido:
			_limite_original = camera.limit_left
			_limite_definido = true
		_transicionar_camera(limite_caverna)

func _on_body_exited(body: Node2D) -> void:
	if body is Player or body.is_in_group("player"):
		_transicionar_camera(_limite_original)

func _transicionar_camera(alvo: int) -> void:
	var camera := _obter_camera()
	if not camera:
		return
	
	if _tween and _tween.is_valid():
		_tween.kill()
		
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(camera, "limit_left", alvo, duracao_transicao)
