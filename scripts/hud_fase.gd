class_name HudFase
extends CanvasLayer

# Interface da fase: contador de chaves, nome da fase, mensagens rápidas,
# barra de vida do chefe, menu de pausa (ESC) e tela de fase concluída.
# A vida (corações) e os diamantes continuam usando os prefabs do grupo.

const TEX_CHAVE := preload("res://assets/misc/novos/chave.png")

var idFase: int = 0
var _label_chaves: Label
var _titulo: Label
var _subtitulo: Label
var _mensagem: Label
var _tween_mensagem: Tween
var _barra_chefe: ProgressBar
var _nome_chefe: Label
var _pausa: Control
var _final: Control
var _botao_continuar: Button

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Contador de chaves (abaixo dos corações)
	var caixa := HBoxContainer.new()
	caixa.position = Vector2(8, 28)
	caixa.add_theme_constant_override("separation", 3)
	add_child(caixa)
	var icone := TextureRect.new()
	icone.texture = TEX_CHAVE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	caixa.add_child(icone)
	_label_chaves = _criar_label(10)
	caixa.add_child(_label_chaves)

	# Nome da fase (aparece no começo e some)
	_titulo = _criar_label(14, Color(1.0, 0.92, 0.55))
	_largura_total(_titulo, 34)
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_titulo)
	_subtitulo = _criar_label(9)
	_largura_total(_subtitulo, 54)
	_subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_subtitulo)

	# Mensagens rápidas ("Checkpoint!", "Faltam 2 chaves"...)
	_mensagem = _criar_label(10, Color(1.0, 1.0, 0.85))
	_largura_total(_mensagem, 128)
	_mensagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mensagem.modulate.a = 0.0
	add_child(_mensagem)

	# Barra de vida do chefe
	_nome_chefe = _criar_label(8, Color(1.0, 0.6, 0.5))
	_nome_chefe.text = "GAMBÁ GIGANTE"
	_largura_total(_nome_chefe, 30)
	_nome_chefe.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nome_chefe.visible = false
	add_child(_nome_chefe)
	_barra_chefe = ProgressBar.new()
	_barra_chefe.show_percentage = false
	_barra_chefe.custom_minimum_size = Vector2(120, 6)
	_barra_chefe.size = Vector2(120, 6)
	_barra_chefe.position = Vector2(100, 44)
	var fundo_barra := StyleBoxFlat.new()
	fundo_barra.bg_color = Color(0.1, 0.05, 0.05, 0.8)
	var cheio_barra := StyleBoxFlat.new()
	cheio_barra.bg_color = Color(0.9, 0.2, 0.15)
	_barra_chefe.add_theme_stylebox_override("background", fundo_barra)
	_barra_chefe.add_theme_stylebox_override("fill", cheio_barra)
	_barra_chefe.visible = false
	add_child(_barra_chefe)

	_pausa = _criar_painel("Pausado", [
		["Continuar", _continuar],
		["Reiniciar fase", _reiniciar],
		["Seletor de fases", _ir_para_seletor],
	])
	_botao_continuar = _pausa.find_child("Continuar", true, false) as Button

func _criar_label(tamanho: int, cor: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", cor)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.1))
	label.add_theme_constant_override("outline_size", 4)
	return label

# Estica o label na largura da tela (para o texto ficar centralizado) na altura y
func _largura_total(label: Label, y: float) -> void:
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.offset_left = 0.0
	label.offset_right = 0.0
	label.offset_top = y
	label.offset_bottom = y + 16.0

# Painel centralizado com título e botões, usado na pausa e no fim da fase
func _criar_painel(titulo: String, botoes: Array) -> Control:
	var fundo := ColorRect.new()
	fundo.color = Color(0.05, 0.02, 0.1, 0.7)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.visible = false
	add_child(fundo)

	var coluna := VBoxContainer.new()
	coluna.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", 4)
	coluna.grow_horizontal = Control.GROW_DIRECTION_BOTH
	coluna.grow_vertical = Control.GROW_DIRECTION_BOTH
	fundo.add_child(coluna)

	var label := _criar_label(14, Color(1.0, 0.85, 0.3))
	label.name = "Titulo"
	label.text = titulo
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(label)

	var info := _criar_label(9)
	info.name = "Info"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(info)

	for dados in botoes:
		var botao := Button.new()
		botao.name = dados[0]
		botao.text = dados[0]
		botao.add_theme_font_size_override("font_size", 10)
		botao.custom_minimum_size = Vector2(110, 0)
		botao.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		botao.pressed.connect(dados[1])
		coluna.add_child(botao)
	return fundo

# ----- Informações -----
func mostrar_titulo(numero: int, nome: String, descricao: String) -> void:
	_titulo.text = "Fase %d - %s" % [numero, nome]
	_subtitulo.text = descricao
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(_titulo, "modulate:a", 0.0, 0.8)
	tween.parallel().tween_property(_subtitulo, "modulate:a", 0.0, 0.8)

func atualizar_chaves(coletadas: int, total: int) -> void:
	_label_chaves.text = "%d/%d" % [coletadas, total]
	if coletadas >= total:
		_label_chaves.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))

func mensagem(texto: String, cor: Color = Color(1.0, 1.0, 0.85)) -> void:
	_mensagem.text = texto
	_mensagem.add_theme_color_override("font_color", cor)
	if _tween_mensagem and _tween_mensagem.is_valid():
		_tween_mensagem.kill()
	_mensagem.modulate.a = 1.0
	_tween_mensagem = create_tween()
	_tween_mensagem.tween_interval(1.6)
	_tween_mensagem.tween_property(_mensagem, "modulate:a", 0.0, 0.5)

func mostrar_barra_chefe(visivel: bool) -> void:
	_barra_chefe.visible = visivel
	_nome_chefe.visible = visivel

func atualizar_barra_chefe(atual: int, maximo: int) -> void:
	_barra_chefe.max_value = maximo
	_barra_chefe.value = atual
	if atual <= 0:
		mostrar_barra_chefe(false)

# ----- Pausa -----
func _unhandled_input(event: InputEvent) -> void:
	if _final and _final.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if _pausa.visible:
			_continuar()
		else:
			_pausa.visible = true
			get_tree().paused = true
			_botao_continuar.grab_focus()
		get_viewport().set_input_as_handled()

func _continuar() -> void:
	_pausa.visible = false
	get_tree().paused = false

func _reiniciar() -> void:
	get_tree().paused = false
	controladorFases.call_deferred("iniciarFase", idFase)

func _ir_para_seletor() -> void:
	get_tree().paused = false
	controladorFases.call_deferred("carregarFase", 0)

# ----- Fim da fase -----
func mostrar_fase_concluida(diamantes: int, total_diamantes: int, ultima_fase: bool) -> void:
	var botoes := []
	if not ultima_fase:
		botoes.append(["Próxima fase", _proxima_fase])
	botoes.append(["Seletor de fases", _ir_para_seletor])
	var titulo := "Você salvou Sunny Land!" if ultima_fase else "Fase %d concluída!" % idFase
	_final = _criar_painel(titulo, botoes)
	var info := _final.find_child("Info", true, false) as Label
	info.text = "Diamantes: %d/%d" % [diamantes, total_diamantes]
	if ultima_fase:
		info.text += "\nObrigado por jogar!"
	_final.visible = true
	_final.modulate.a = 0.0
	create_tween().tween_property(_final, "modulate:a", 1.0, 0.4)
	(_final.find_child("Próxima fase" if not ultima_fase else "Seletor de fases", true, false) as Button).grab_focus()

func _proxima_fase() -> void:
	controladorFases.call_deferred("iniciarFase", idFase + 1)
