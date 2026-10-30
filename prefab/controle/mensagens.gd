extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var ganhou: Label = $ganhou
@onready var morreu: Label = $morreu

func _ready() -> void:
	esconder_tudo()

# Esconder todas as mensagems
func esconder_tudo() -> void:
	color_rect.hide()
	ganhou.hide()
	morreu.hide()

# Mostra a mensagem que passou de fase
func mostrar_ganhou() -> void:
	esconder_tudo()
	color_rect.show()
	ganhou.show()

# Mostra a mensagem que o jogador morreu
func mostrar_morreu() -> void:
	esconder_tudo()
	color_rect.show()
	morreu.show()
