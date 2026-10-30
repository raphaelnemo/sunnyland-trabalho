extends Node

# Autoload que controla qual fase está carregada, o progresso (fases liberadas /
# completadas) e o estado da tentativa atual (chaves coletadas e checkpoint).

const ARQUIVO_PROGRESSO := "user://progresso.cfg"
const TOTAL_FASES := 5

var principal  : Node2D = null
var faseCarregada : fase = null
var idFaseAtual  : int = -1

var fasesDisponiveis : Array[dadosFase]

# Estado da tentativa atual (é mantido quando o jogador morre e a fase recarrega)
var chavesColetadas : Array[int] = []
var checkpointAtivo : bool = false
var posicaoCheckpoint : Vector2 = Vector2.ZERO

func fecharfase() -> void :
	if is_instance_valid(faseCarregada):
		# Remove da árvore na hora para a fase antiga não interferir na nova
		# (câmera, contagem de diamantes, sinais...)
		if faseCarregada.get_parent():
			faseCarregada.get_parent().remove_child(faseCarregada)
		faseCarregada.queue_free()

	faseCarregada = null

# Começa uma fase do zero (vindo do seletor ou do botão "reiniciar")
func iniciarFase(idFase : int) -> void:
	limparTentativa()
	carregarFase(idFase)

func carregarFase(idFase : int) -> void:
	print("Carregando: %s" % idFase)
	get_tree().paused = false

	if idFase != idFaseAtual:
		limparTentativa()

	fecharfase()

	var dadofase = carregarDados(idFase)

	if not dadofase:
		print("erro fase não esta no Array")
		return

	idFaseAtual = idFase
	var caminhoFase = "res://fases/%s/fase.tscn" % idFase
	var faseCaminho := load(caminhoFase)

	if faseCaminho:
		faseCarregada = faseCaminho.instantiate() as fase

		if is_instance_valid(faseCarregada):
			principal.add_child(faseCarregada)
		else:
			print("erro ao instanciar a fase")
	else:
		print("Fase não existe")

func carregarDados(id : int) -> dadosFase:
	var faseRetornando : dadosFase = null

	for nivel : dadosFase in fasesDisponiveis:
		if nivel.idFase == id:
			faseRetornando = nivel

	return faseRetornando

func estaDesbloqueada(id : int) -> bool:
	for faseCarregada in fasesDisponiveis:
		if faseCarregada.idFase == id:
			return faseCarregada.faseDesbloqueada
	return false

func desbloquearFase(id : int) -> void:
	for faseCarregada in fasesDisponiveis:
		if faseCarregada.idFase == id && !estaDesbloqueada(id):
			faseCarregada.faseDesbloqueada = true

func estaCompletada(id : int) -> bool:
	for faseCarregada in fasesDisponiveis:
		if faseCarregada.idFase == id:
			return faseCarregada.faseCompletada
	return false

func faseCompletada(id : int) -> void:
	for faseCarregada in fasesDisponiveis:
		if faseCarregada.idFase == id && !estaCompletada(id):
			faseCarregada.faseCompletada = true

# Marca a fase como completa, libera a próxima e salva no disco
func concluirFase(id : int) -> void:
	faseCompletada(id)
	desbloquearFase(id + 1)
	limparTentativa()
	salvarProgresso()

# ----- Chaves e checkpoint da tentativa atual -----
func limparTentativa() -> void:
	chavesColetadas.clear()
	checkpointAtivo = false
	posicaoCheckpoint = Vector2.ZERO

func registrarChave(idChave : int) -> void:
	if not chavesColetadas.has(idChave):
		chavesColetadas.append(idChave)

func chaveJaColetada(idChave : int) -> bool:
	return chavesColetadas.has(idChave)

func salvarCheckpoint(posicao : Vector2) -> void:
	checkpointAtivo = true
	posicaoCheckpoint = posicao

# ----- Música (fica no autoload para não reiniciar quando a fase recarrega) -----
var _musica : AudioStreamPlayer

func tocarMusica(tom : float) -> void:
	if not is_instance_valid(_musica):
		_musica = AudioStreamPlayer.new()
		var faixa := (load("res://assets/musica/walkyandtalky.ogg") as AudioStream).duplicate()
		if "loop" in faixa:
			faixa.loop = true
		_musica.stream = faixa
		_musica.volume_db = -10.0
		_musica.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_musica)
	# Cada cenário toca a música num tom diferente (mais grave na caverna, mais agudo no fim)
	_musica.pitch_scale = tom
	if not _musica.playing:
		_musica.play()

# ----- Progresso salvo -----
func salvarProgresso() -> void:
	var arquivo := ConfigFile.new()
	for nivel in fasesDisponiveis:
		arquivo.set_value("fases", "desbloqueada_%d" % nivel.idFase, nivel.faseDesbloqueada)
		arquivo.set_value("fases", "completada_%d" % nivel.idFase, nivel.faseCompletada)
	arquivo.save(ARQUIVO_PROGRESSO)

func carregarProgresso() -> void:
	var arquivo := ConfigFile.new()
	if arquivo.load(ARQUIVO_PROGRESSO) != OK:
		return
	for nivel in fasesDisponiveis:
		nivel.faseDesbloqueada = nivel.faseDesbloqueada or arquivo.get_value("fases", "desbloqueada_%d" % nivel.idFase, false)
		nivel.faseCompletada = arquivo.get_value("fases", "completada_%d" % nivel.idFase, false)

func apagarProgresso() -> void:
	for nivel in fasesDisponiveis:
		nivel.faseCompletada = false
		nivel.faseDesbloqueada = nivel.idFase <= 1
	salvarProgresso()
