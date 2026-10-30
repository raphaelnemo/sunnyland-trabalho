extends Area2D
# Usar class_name para permitir que outros scripts herdem deste
class_name CollectibleItem

@onready var anim: AnimatedSprite2D = $anim

# Exportar essa variável permite definir valores diferentes (pontos) para cada item. Exemplo cherry = 1, gem = 5
@export var score_value: int = 1

func _ready() -> void:
	# Conectar os sinais nativos via código
	body_entered.connect(_on_body_entered)
	anim.animation_finished.connect(_on_animation_finished)

func _on_body_entered(body: Node2D) -> void:
	# Evita que o player colete o mesmo item duas vezes no mesmo frame$
	_collect()

# Usamos uma função própria que poderá ser estendida/modificada se necessário
func _collect() -> void:
	anim.play("collect")
	# Futuramente, a lógica de som e envio de pontuação para o HUD entrará aqui

func _on_animation_finished() -> void:
	# Quando a animação de coleta acabar, remove o item da árvore
	if anim.animation == "collect":
		queue_free()
