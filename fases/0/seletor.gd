extends Control

# Seletor de fases: só deixa entrar nas fases liberadas.
# Uma fase é liberada quando o jogador pega todas as chaves da fase anterior
# e passa pela porta de saída.

@onready var botoes : Array = $VBoxContainer/fases.get_children()
@onready var info : Label = $VBoxContainer/info

func _ready() -> void:
	controladorFases.tocarMusica(1.0)
	for i in botoes.size():
		botoes[i].focus_entered.connect(_mostrar_info.bind(i + 1))
		botoes[i].mouse_entered.connect(_mostrar_info.bind(i + 1))
	_atualizar_botoes()

func _atualizar_botoes() -> void:
	var primeiro_livre : Button = null
	for i in botoes.size():
		var idFase := i + 1
		var botao : Button = botoes[i]
		var liberada := controladorFases.estaDesbloqueada(idFase)
		botao.disabled = not liberada
		botao.text = str(idFase) if liberada else "X"
		if controladorFases.estaCompletada(idFase):
			botao.text = "%d*" % idFase
		if liberada:
			primeiro_livre = botao
	info.text = "Pegue as chaves para liberar a próxima fase"
	if primeiro_livre:
		primeiro_livre.grab_focus()

func _mostrar_info(idFase : int) -> void:
	var dados := controladorFases.carregarDados(idFase)
	if not dados:
		return
	if controladorFases.estaDesbloqueada(idFase):
		var estado := " (completa)" if controladorFases.estaCompletada(idFase) else ""
		info.text = "%d - %s%s" % [idFase, dados.nomeFase, estado]
	else:
		info.text = "%d - Bloqueada: termine a fase %d" % [idFase, idFase - 1]

func _abrir(idFase : int) -> void:
	if controladorFases.estaDesbloqueada(idFase):
		controladorFases.call_deferred("iniciarFase", idFase)

func _on_voltar_pressed() -> void:
	controladorFases.faseCarregada = null
	controladorFases.idFaseAtual = -1
	get_tree().change_scene_to_file("res://principal.tscn")

func _on_apagar_pressed() -> void:
	controladorFases.apagarProgresso()
	_atualizar_botoes()

func _on_1_pressed() -> void:
	_abrir(1)

func _on_button_2_pressed() -> void:
	_abrir(2)

func _on_button_3_pressed() -> void:
	_abrir(3)

func _on_button_4_pressed() -> void:
	_abrir(4)

func _on_button_5_pressed() -> void:
	_abrir(5)
