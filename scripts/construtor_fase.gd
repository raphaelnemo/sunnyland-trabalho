class_name ConstrutorFase
extends fase

# Monta uma fase inteira a partir dos dados em niveis.gd:
#  - lê o mapa em texto (cada caractere é uma célula de 16x16)
#  - cria o tilemap com os tiles do tema (grama, rocha, tijolos...)
#  - monta o cenário (céu, nuvens, floresta ao fundo, partículas, luz, água/lava)
#  - posiciona jogador, inimigos (com a dificuldade da fase), itens, chaves e porta
#
# Legenda do mapa (veja também niveis.gd):
#   #  chão/parede          =  plataforma (atravessável por baixo)
#   L  topo de escada       H  escada
#   P  início do jogador    D  porta de saída     C  checkpoint
#   K  chave                g  diamante           c  cereja
#   o  gambá   f  sapo   e  águia (sobe/desce)   h  águia (vai e volta)
#   b  morcego              B  chefe (gambá gigante)
#   ^  espinhos             M  plataforma móvel horizontal   V  plataforma móvel vertical
#   X  plataforma que cai   t  tocha               1-7  enfeites do tema

const TAM := 16
const ID_CHAVE_CHEFE := 100

const TERRENO := preload("res://assets/environment/world/tiles/terrain.png")
const TEX_NUVENS := preload("res://assets/environment/background/back.png")
const TEX_FLORESTA := preload("res://assets/environment/background/middle - Copia.png")
const CENA_JOGADOR := preload("res://actors/player.tscn")
const CENA_GAMBA := preload("res://actors/opossum.tscn")
const CENA_SAPO := preload("res://actors/frog.tscn")
const CENA_AGUIA := preload("res://actors/eagle.tscn")
const CENA_CEREJA := preload("res://prefabs/cherry.tscn")
const CENA_DIAMANTE := preload("res://prefabs/gem.tscn")
const CENA_ESCADA := preload("res://prefabs/escada.tscn")
const CENA_PLAT_MOVEL := preload("res://prefabs/moving_plataform.tscn")
const CENA_UI_VIDA := preload("res://prefabs/ui/vida_ui.tscn")
const CENA_UI_PONTOS := preload("res://prefabs/ui/pontuacao_ui.tscn")
const SCRIPT_CHEFE := preload("res://scripts/objetos/chefe.gd")

# Conjuntos de tiles do terrain.png (coordenadas no atlas, em células de 16px)
const SOLOS := {
	"grama": {"topo": [Vector2i(1, 1), Vector2i(3, 1), Vector2i(5, 1)], "sub": [Vector2i(1, 5), Vector2i(3, 5), Vector2i(5, 5)], "fundo": [Vector2i(3, 3)]},
	"rocha": {"topo": [Vector2i(7, 1)], "sub": [Vector2i(1, 3), Vector2i(5, 3), Vector2i(7, 7)], "fundo": [Vector2i(3, 3)]},
	# tijolos do templo usam 9 partes (cantos, bordas e meio)
	"tijolo": {"nove_partes": true},
}
const PLATAFORMAS := {
	"grama_flutuante": {"esq": Vector2i(15, 14), "meio": Vector2i(17, 14), "dir": Vector2i(19, 14), "fina": false},
	"tronco": {"esq": Vector2i(9, 1), "meio": Vector2i(10, 1), "dir": Vector2i(8, 3), "fina": true},
	"tijolo": {"esq": Vector2i(15, 7), "meio": Vector2i(17, 7), "dir": Vector2i(19, 7), "fina": false},
}

# Visual de cada cenário
const TEMAS := {
	"floresta": {
		"solo": "grama", "plataforma": "grama_flutuante", "cor_tiles": Color(1, 1, 1),
		"ceu": [Color(0.36, 0.72, 0.95), Color(0.78, 0.93, 1.0)],
		"nuvens": Color(1, 1, 1), "floresta": Color(1, 1, 1), "ambiente": Color(1, 1, 1),
		"luz_jogador": false, "particulas": "folhas", "liquido": null, "tom": 1.0,
		"enfeites": {"1": "bush", "2": "tree", "3": "pine", "4": "rock", "5": "shrooms", "6": "sign", "7": "wooden-house"},
	},
	"pantano": {
		"solo": "grama", "plataforma": "tronco", "cor_tiles": Color(0.86, 0.8, 0.68),
		"ceu": [Color(0.42, 0.22, 0.48), Color(1.0, 0.62, 0.36)],
		"nuvens": Color(1.0, 0.62, 0.5), "floresta": Color(0.42, 0.32, 0.38), "ambiente": Color(1.0, 0.86, 0.78),
		"luz_jogador": false, "particulas": "vagalumes", "liquido": Color(0.22, 0.42, 0.3, 0.9), "tom": 0.92,
		"enfeites": {"1": "bush", "2": "palm", "3": "rock-1", "4": "shrooms", "5": "rock-2", "6": "sign", "7": "straw-house"},
	},
	"caverna": {
		"solo": "rocha", "plataforma": "tronco", "cor_tiles": Color(0.82, 0.76, 0.95),
		"ceu": [Color(0.04, 0.02, 0.07), Color(0.14, 0.09, 0.2)],
		"nuvens": null, "floresta": Color(0.16, 0.1, 0.22), "ambiente": Color(0.3, 0.26, 0.42),
		"luz_jogador": true, "particulas": "poeira", "liquido": null, "tom": 0.8,
		"enfeites": {"1": "rock", "2": "skulls", "3": "shrooms", "4": "crate", "5": "spike-skull", "6": "sign", "7": "big-crate"},
	},
	"ceu": {
		"solo": "tijolo", "plataforma": "grama_flutuante", "cor_tiles": Color(0.86, 0.86, 1.0),
		"ceu": [Color(0.1, 0.08, 0.32), Color(0.62, 0.48, 0.78)],
		"nuvens": Color(0.62, 0.6, 0.95), "floresta": null, "ambiente": Color(0.82, 0.82, 1.0),
		"luz_jogador": false, "particulas": "estrelas", "liquido": null, "tom": 1.05,
		"enfeites": {"1": "bush", "2": "pine", "3": "rock", "4": "block", "5": "face-block", "6": "sign", "7": "tree-house"},
	},
	"vulcao": {
		"solo": "tijolo", "plataforma": "tijolo", "cor_tiles": Color(1.0, 0.62, 0.56),
		"ceu": [Color(0.12, 0.02, 0.04), Color(0.62, 0.16, 0.08)],
		"nuvens": Color(0.7, 0.24, 0.18), "floresta": Color(0.24, 0.05, 0.05), "ambiente": Color(0.78, 0.6, 0.6),
		"luz_jogador": true, "particulas": "brasas", "liquido": Color(1.0, 0.42, 0.06, 1.0), "tom": 1.12,
		"enfeites": {"1": "skulls", "2": "spike-skull", "3": "rock", "4": "big-crate", "5": "face-block", "6": "sign", "7": "block-big"},
	},
}

var dados: Dictionary
var tema: Dictionary
var mapa: Array[String] = []
var largura: int = 0
var altura: int = 0

var jogador: Player
var camera: Camera2D
var hud: HudFase
var porta: PortaTrancada
var chefe: CharacterBody2D
var ui_pontos: Node
var total_chaves: int = 0
var chaves_coletadas: int = 0

var _terreno: TileMapLayer
var _fonte: TileSetAtlasSource
var _alternativas: Dictionary = {}
var _coords_usadas: Dictionary = {}
var _mundo: Node2D

static var _textura_luz: GradientTexture2D

# Textura redonda e suave usada por todas as luzes (jogador, tochas, chaves, lava)
static func textura_luz() -> Texture2D:
	if _textura_luz == null:
		var gradiente := Gradient.new()
		gradiente.set_color(0, Color(1, 1, 1, 1))
		gradiente.set_color(1, Color(1, 1, 1, 0))
		_textura_luz = GradientTexture2D.new()
		_textura_luz.gradient = gradiente
		_textura_luz.fill = GradientTexture2D.FILL_RADIAL
		_textura_luz.fill_from = Vector2(0.5, 0.5)
		_textura_luz.fill_to = Vector2(0.5, 0.0)
		_textura_luz.width = 128
		_textura_luz.height = 128
	return _textura_luz

func _ready() -> void:
	super._ready()
	dados = Niveis.obter(idFase)
	tema = TEMAS[dados.tema]
	_montar_mapa()

	_criar_fundo()
	_mundo = Node2D.new()
	_mundo.name = "Mundo"
	add_child(_mundo)
	_criar_tiles()
	_criar_limites()
	_criar_liquido()

	camera = Camera2D.new()
	camera.name = "Camera"
	camera.add_to_group("main_camera")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = largura * TAM
	camera.limit_bottom = altura * TAM
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	add_child(camera)

	_criar_objetos()
	_criar_particulas()
	_criar_interface()

	if tema.ambiente != Color(1, 1, 1):
		var ambiente := CanvasModulate.new()
		ambiente.color = tema.ambiente
		add_child(ambiente)

	controladorFases.tocarMusica(tema.tom)

# ==============================================================================
# MAPA
# ==============================================================================
# Junta os segmentos lado a lado. Cada segmento é uma lista de linhas; linhas
# curtas são completadas com "." para todos terem a mesma largura.
func _montar_mapa() -> void:
	var segmentos: Array = dados.segmentos
	altura = 0
	for segmento in segmentos:
		altura = maxi(altura, segmento.size())
	for y in altura:
		mapa.append("")
	for segmento in segmentos:
		var largura_segmento := 0
		for linha in segmento:
			largura_segmento = maxi(largura_segmento, linha.length())
		for linha in segmento:
			if linha.length() != largura_segmento:
				push_warning("Fase %d: linha com tamanho diferente no segmento %d: \"%s\"" % [idFase, segmentos.find(segmento), linha])
		# Segmentos mais baixos são alinhados pelo chão (completados por cima)
		var deslocamento: int = altura - segmento.size()
		for y in altura:
			var linha: String = "" if y < deslocamento else segmento[y - deslocamento]
			mapa[y] += linha.rpad(largura_segmento, ".")
	largura = mapa[0].length()

func celula(x: int, y: int) -> String:
	if y < 0:
		return "."
	if y >= altura:
		return celula(x, altura - 1)
	x = clampi(x, 0, largura - 1)
	return mapa[y][x]

func solido(x: int, y: int) -> bool:
	return celula(x, y) == "#"

func plataforma(x: int, y: int) -> bool:
	var c := celula(x, y)
	return c == "=" or c == "L"

# Posição no mundo do pé de uma célula (meio da borda de baixo)
func pe(x: int, y: int) -> Vector2:
	return Vector2(x * TAM + TAM / 2.0, (y + 1) * TAM)

func centro(x: int, y: int) -> Vector2:
	return Vector2(x * TAM + TAM / 2.0, y * TAM + TAM / 2.0)

# ==============================================================================
# TILES
# ==============================================================================
func _criar_tiles() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TAM, TAM)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 6)
	_fonte = TileSetAtlasSource.new()
	_fonte.texture = TERRENO
	_fonte.texture_region_size = Vector2i(TAM, TAM)
	tileset.add_source(_fonte, 0)

	_terreno = TileMapLayer.new()
	_terreno.name = "Terreno"
	_terreno.tile_set = tileset
	_terreno.self_modulate = tema.cor_tiles
	_mundo.add_child(_terreno)

	var solo: Dictionary = SOLOS[tema.solo]
	var plat: Dictionary = PLATAFORMAS[tema.plataforma]
	for y in altura:
		for x in largura:
			if solido(x, y):
				_colocar(x, y, _tile_solo(solo, x, y), false, false)
			elif plataforma(x, y):
				var esq := plataforma(x - 1, y)
				var dir := plataforma(x + 1, y)
				var coord: Vector2i = plat.meio
				if not esq and dir:
					coord = plat.esq
				elif esq and not dir:
					coord = plat.dir
				_colocar(x, y, coord, true, plat.fina)

func _tile_solo(solo: Dictionary, x: int, y: int) -> Vector2i:
	if solo.has("nove_partes"):
		var cima := not solido(x, y - 1)
		var baixo := not solido(x, y + 1)
		var esq := not solido(x - 1, y)
		var dir := not solido(x + 1, y)
		var coluna := 17
		if esq and not dir:
			coluna = 15
		elif dir and not esq:
			coluna = 19
		var linha := 9
		if cima:
			linha = 7
		elif baixo:
			linha = 11
		return Vector2i(coluna, linha)
	# Variação "aleatória" fixa pela posição, para o chão não ficar repetitivo
	var variacao := absi(x * 7 + y * 13)
	if not solido(x, y - 1):
		return solo.topo[variacao % solo.topo.size()]
	if not solido(x, y - 2):
		return solo.sub[variacao % solo.sub.size()]
	return solo.fundo[variacao % solo.fundo.size()]

# Coloca um tile criando (uma vez só) a colisão dele no tileset.
# A mesma coordenada pode existir como bloco sólido e como plataforma de mão única
# (usando um tile alternativo).
func _colocar(x: int, y: int, coord: Vector2i, mao_unica: bool, fina: bool) -> void:
	var chave := "%d,%d,%s,%s" % [coord.x, coord.y, mao_unica, fina]
	if not _alternativas.has(chave):
		if not _fonte.has_tile(coord):
			_fonte.create_tile(coord)
		var alternativa := 0
		if _coords_usadas.has(coord):
			alternativa = _fonte.create_alternative_tile(coord)
		_coords_usadas[coord] = true
		var tile := _fonte.get_tile_data(coord, alternativa)
		var base := -1.0 if fina else 8.0
		tile.add_collision_polygon(0)
		tile.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, base), Vector2(-8, base)]))
		tile.set_collision_polygon_one_way(0, 0, mao_unica)
		_alternativas[chave] = alternativa
	_terreno.set_cell(Vector2i(x, y), 0, coord, _alternativas[chave])

# Paredes invisíveis nas laterais e área de morte embaixo do mapa
func _criar_limites() -> void:
	var paredes := StaticBody2D.new()
	paredes.name = "Limites"
	for lado in [-8.0, largura * TAM + 8.0]:
		var forma := CollisionShape2D.new()
		var retangulo := RectangleShape2D.new()
		retangulo.size = Vector2(16, altura * TAM + 400)
		forma.shape = retangulo
		forma.position = Vector2(lado, altura * TAM / 2.0 - 200)
		paredes.add_child(forma)
	_mundo.add_child(paredes)

	var abismo := ZonaMorte.new()
	abismo.name = "Abismo"
	var forma_abismo := CollisionShape2D.new()
	var retangulo_abismo := RectangleShape2D.new()
	retangulo_abismo.size = Vector2(largura * TAM + 200, 32)
	forma_abismo.shape = retangulo_abismo
	abismo.position = Vector2(largura * TAM / 2.0, altura * TAM + 48)
	abismo.add_child(forma_abismo)
	_mundo.add_child(abismo)

# Água (pântano) ou lava (vulcão) no fundo dos buracos
func _criar_liquido() -> void:
	if not (tema.liquido is Color):
		return
	var cor: Color = tema.liquido
	var topo := (altura - 1) * TAM + 6.0
	var liquido := Polygon2D.new()
	liquido.name = "Liquido"
	liquido.color = cor
	liquido.z_index = 5
	liquido.polygon = PackedVector2Array([Vector2(0, topo), Vector2(largura * TAM, topo), Vector2(largura * TAM, topo + 300), Vector2(0, topo + 300)])
	_mundo.add_child(liquido)

	# Faixa clara na superfície que "ondula"
	var superficie := Line2D.new()
	superficie.width = 2.0
	superficie.default_color = cor.lightened(0.45)
	superficie.z_index = 6
	for i in range(0, largura * TAM + 1, 8):
		superficie.add_point(Vector2(i, topo + (1.0 if (i / 8) % 2 == 0 else 0.0)))
	_mundo.add_child(superficie)
	var onda := create_tween().set_loops()
	onda.tween_property(superficie, "position:x", -8.0, 0.8)
	onda.tween_property(superficie, "position:x", 0.0, 0.8)

	var zona := ZonaMorte.new()
	zona.name = "ZonaLiquido"
	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(largura * TAM, 24)
	forma.shape = retangulo
	zona.position = Vector2(largura * TAM / 2.0, topo + 18)
	zona.add_child(forma)
	_mundo.add_child(zona)

	# Lava brilha
	if dados.tema == "vulcao":
		for x in range(64, largura * TAM, 160):
			var luz := PointLight2D.new()
			luz.texture = textura_luz()
			luz.texture_scale = 2.5
			luz.color = Color(1.0, 0.5, 0.2)
			luz.energy = 0.9
			luz.position = Vector2(x, topo)
			_mundo.add_child(luz)

# ==============================================================================
# CENÁRIO DE FUNDO
# ==============================================================================
func _criar_fundo() -> void:
	# Céu em degradê, desenhado atrás de tudo
	var camada_ceu := CanvasLayer.new()
	camada_ceu.name = "Ceu"
	camada_ceu.layer = -10
	add_child(camada_ceu)
	var gradiente := Gradient.new()
	gradiente.set_color(0, tema.ceu[0])
	gradiente.set_color(1, tema.ceu[1])
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.fill_from = Vector2(0, 0)
	textura.fill_to = Vector2(0, 1)
	var ceu := TextureRect.new()
	ceu.texture = textura
	ceu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ceu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ceu.stretch_mode = TextureRect.STRETCH_SCALE
	camada_ceu.add_child(ceu)

	if dados.tema == "ceu":
		_criar_estrelas(camada_ceu)

	# Nuvens e mar (camada distante)
	if tema.nuvens is Color:
		var nuvens := Parallax2D.new()
		nuvens.name = "Nuvens"
		nuvens.scroll_scale = Vector2(0.15, 0.0)
		nuvens.repeat_size = Vector2(TEX_NUVENS.get_width(), 0)
		nuvens.repeat_times = 4
		nuvens.z_index = -20
		var sprite := Sprite2D.new()
		sprite.texture = TEX_NUVENS
		sprite.centered = false
		sprite.position = Vector2(0, -40)
		sprite.modulate = tema.nuvens
		nuvens.add_child(sprite)
		add_child(nuvens)

	# Silhueta da floresta / rochas (camada do meio)
	if tema.floresta is Color:
		var meio := Parallax2D.new()
		meio.name = "Floresta"
		meio.scroll_scale = Vector2(0.4, 0.0)
		meio.repeat_size = Vector2(TEX_FLORESTA.get_width(), 0)
		meio.repeat_times = 4
		meio.z_index = -15
		var sprite_meio := Sprite2D.new()
		sprite_meio.texture = TEX_FLORESTA
		sprite_meio.centered = false
		sprite_meio.position = Vector2(0, 70)
		sprite_meio.modulate = tema.floresta
		meio.add_child(sprite_meio)
		add_child(meio)

func _criar_estrelas(camada: CanvasLayer) -> void:
	var estrelas := CPUParticles2D.new()
	estrelas.amount = 45
	estrelas.lifetime = 4.0
	estrelas.preprocess = 4.0
	estrelas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	estrelas.emission_rect_extents = Vector2(170, 60)
	estrelas.position = Vector2(160, 60)
	estrelas.gravity = Vector2.ZERO
	estrelas.initial_velocity_min = 0.0
	estrelas.initial_velocity_max = 0.0
	estrelas.scale_amount_min = 1.0
	estrelas.scale_amount_max = 2.0
	var brilho := Gradient.new()
	brilho.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	brilho.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 0.9, 1), Color(1, 1, 1, 0)])
	estrelas.color_ramp = brilho
	camada.add_child(estrelas)

# Partículas do clima de cada cenário. Ficam presas na câmera, mas soltam as
# partículas no mundo (local_coords = false), então parecem fazer parte da fase.
func _criar_particulas() -> void:
	var p := CPUParticles2D.new()
	p.name = "Clima"
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.z_index = 8
	match tema.particulas:
		"folhas":
			p.amount = 14
			p.lifetime = 7.0
			p.emission_rect_extents = Vector2(220, 4)
			p.position = Vector2(0, -110)
			p.gravity = Vector2(6, 22)
			p.initial_velocity_min = 5.0
			p.initial_velocity_max = 15.0
			p.angular_velocity_min = -90.0
			p.angular_velocity_max = 90.0
			p.scale_amount_min = 2.0
			p.scale_amount_max = 3.0
			p.color = Color(0.45, 0.75, 0.25)
		"vagalumes":
			p.amount = 24
			p.lifetime = 4.0
			p.emission_rect_extents = Vector2(200, 100)
			p.gravity = Vector2(0, -4)
			p.initial_velocity_min = 4.0
			p.initial_velocity_max = 14.0
			p.spread = 180.0
			p.scale_amount_min = 1.5
			p.scale_amount_max = 2.0
			var brilho := Gradient.new()
			brilho.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
			brilho.colors = PackedColorArray([Color(1, 1, 0.4, 0), Color(1, 1, 0.5, 1), Color(0.8, 1, 0.3, 1), Color(1, 1, 0.4, 0)])
			p.color_ramp = brilho
		"poeira":
			p.amount = 30
			p.lifetime = 6.0
			p.emission_rect_extents = Vector2(200, 100)
			p.gravity = Vector2(2, 3)
			p.initial_velocity_min = 2.0
			p.initial_velocity_max = 6.0
			p.spread = 180.0
			p.color = Color(0.75, 0.7, 0.85, 0.6)
		"estrelas":
			p.amount = 10
			p.lifetime = 5.0
			p.emission_rect_extents = Vector2(200, 100)
			p.gravity = Vector2(-12, 0)
			p.initial_velocity_min = 2.0
			p.initial_velocity_max = 5.0
			p.scale_amount_min = 1.0
			p.scale_amount_max = 2.0
			p.color = Color(0.85, 0.85, 1.0, 0.7)
		"brasas":
			p.amount = 40
			p.lifetime = 3.5
			p.emission_rect_extents = Vector2(220, 10)
			p.position = Vector2(0, 100)
			p.gravity = Vector2(0, -30)
			p.initial_velocity_min = 5.0
			p.initial_velocity_max = 25.0
			p.spread = 40.0
			p.direction = Vector2(0, -1)
			p.scale_amount_min = 1.0
			p.scale_amount_max = 2.0
			var cores := Gradient.new()
			cores.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
			cores.colors = PackedColorArray([Color(1, 0.9, 0.3, 1), Color(1, 0.45, 0.1, 1), Color(0.5, 0.1, 0.05, 0)])
			p.color_ramp = cores
	camera.add_child(p)

# ==============================================================================
# OBJETOS DO MAPA
# ==============================================================================
func _criar_objetos() -> void:
	var inimigos := Node2D.new()
	inimigos.name = "Inimigos"
	var itens := Node2D.new()
	itens.name = "Itens"
	var enfeites := Node2D.new()
	enfeites.name = "Enfeites"
	enfeites.z_index = -5
	_mundo.add_child(enfeites)
	_mundo.add_child(itens)
	_mundo.add_child(inimigos)

	var inicio := Vector2.ZERO
	var id_chave := 0
	var checkpoints: Array[Checkpoint] = []

	for y in altura:
		for x in largura:
			var c := celula(x, y)
			match c:
				"P":
					inicio = pe(x, y)
				"D":
					porta = PortaTrancada.new()
					porta.position = pe(x, y)
					itens.add_child(porta)
				"C":
					var bandeira := Checkpoint.new()
					bandeira.position = pe(x, y)
					itens.add_child(bandeira)
					checkpoints.append(bandeira)
				"K":
					total_chaves += 1
					if controladorFases.chaveJaColetada(id_chave):
						chaves_coletadas += 1
					else:
						_criar_chave(centro(x, y), id_chave, itens)
					id_chave += 1
				"g":
					var diamante := CENA_DIAMANTE.instantiate()
					diamante.position = centro(x, y)
					itens.add_child(diamante)
				"c":
					var cereja := CENA_CEREJA.instantiate()
					cereja.position = centro(x, y)
					itens.add_child(cereja)
				"^":
					var espinho := Espinho.new()
					espinho.position = pe(x, y)
					itens.add_child(espinho)
				"X":
					var cai := PlataformaCai.new()
					cai.position = centro(x, y)
					cai.tempo_aviso = dados.get("plataforma_cai", 0.5)
					cai.cor = tema.cor_tiles
					itens.add_child(cai)
				"M", "V":
					_criar_plataforma_movel(x, y, c == "V", itens)
				"t":
					_criar_tocha(centro(x, y), enfeites)
				"o", "f", "e", "h", "b":
					inimigos.add_child(_criar_inimigo(c, x, y))
				"B":
					if controladorFases.chaveJaColetada(ID_CHAVE_CHEFE):
						chaves_coletadas += 1
					else:
						chefe = _criar_chefe(x, y)
						inimigos.add_child(chefe)
					total_chaves += 1
				_:
					if tema.enfeites.has(c):
						_criar_enfeite(tema.enfeites[c], pe(x, y), enfeites)
	_criar_escadas(itens)

	# Checkpoint já pego numa tentativa anterior (o jogador morreu e a fase recarregou)
	if controladorFases.checkpointAtivo:
		for bandeira in checkpoints:
			if bandeira.global_position.distance_to(controladorFases.posicaoCheckpoint) < 1.0:
				bandeira.marcar_ativo()
				inicio = controladorFases.posicaoCheckpoint

	for bandeira in checkpoints:
		bandeira.ativado.connect(func(): hud.mensagem("Checkpoint!", Color(0.5, 1.0, 0.5)))

	if porta:
		porta.tentou_abrir_trancada.connect(_on_porta_trancada)
		porta.jogador_entrou.connect(_concluir_fase)
		if chaves_coletadas >= total_chaves:
			porta.destrancar()

	jogador = CENA_JOGADOR.instantiate()
	jogador.position = inicio - Vector2(0, 16)
	_mundo.add_child(jogador)
	jogador.remote_transform_2d.remote_path = jogador.remote_transform_2d.get_path_to(camera)
	camera.global_position = jogador.global_position
	camera.reset_smoothing()

	if tema.luz_jogador:
		var luz := PointLight2D.new()
		luz.texture = textura_luz()
		luz.texture_scale = 2.6
		luz.energy = 1.1
		luz.color = Color(1.0, 0.92, 0.75)
		jogador.add_child(luz)

func _criar_chave(posicao: Vector2, id_chave: int, pai: Node) -> void:
	var chave := Chave.new()
	chave.idChave = id_chave
	chave.position = posicao
	chave.chave_coletada.connect(_on_chave_coletada)
	pai.add_child(chave)

func _criar_enfeite(nome: String, posicao: Vector2, pai: Node) -> void:
	var textura := load("res://assets/environment/props/%s.png" % nome) as Texture2D
	if textura == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = textura
	sprite.offset = Vector2(0, -textura.get_height() / 2.0)
	sprite.position = posicao
	sprite.modulate = tema.cor_tiles
	pai.add_child(sprite)

func _criar_tocha(posicao: Vector2, pai: Node) -> void:
	var tocha := Sprite2D.new()
	tocha.texture = TERRENO
	tocha.region_enabled = true
	tocha.region_rect = Rect2(17 * TAM, 20 * TAM, TAM, TAM)
	tocha.position = posicao
	pai.add_child(tocha)
	var luz := PointLight2D.new()
	luz.texture = textura_luz()
	luz.texture_scale = 1.8
	luz.color = Color(1.0, 0.65, 0.3)
	luz.energy = 1.0
	tocha.add_child(luz)
	# Chama tremulando
	var tremor := create_tween().set_loops()
	tremor.tween_property(luz, "energy", 0.75, 0.15)
	tremor.tween_property(luz, "energy", 1.05, 0.2)

func _criar_plataforma_movel(x: int, y: int, vertical: bool, pai: Node) -> void:
	var config: Dictionary = dados.get("plataforma_movel", {})
	var plat := CENA_PLAT_MOVEL.instantiate()
	plat.position = Vector2(x * TAM + TAM, y * TAM + TAM / 2.0)
	plat.speed = config.get("velocidade", 40.0)
	plat.wait_time = config.get("espera", 0.8)
	if vertical:
		plat.direction = Vector2.UP
		plat.distance = config.get("distancia_v", 64.0)
	else:
		plat.direction = Vector2.RIGHT
		plat.distance = config.get("distancia_h", 64.0)
	plat.get_node("Sprite2D").modulate = tema.cor_tiles
	pai.add_child(plat)

# Escadas: cada sequência vertical de L/H vira uma escada só
func _criar_escadas(pai: Node) -> void:
	for x in largura:
		var y := 0
		while y < altura:
			var c := celula(x, y)
			if c == "L" or c == "H":
				var inicio_y := y
				while y < altura and (celula(x, y) == "L" or celula(x, y) == "H"):
					y += 1
				var escada := CENA_ESCADA.instantiate()
				# Sobra meio tile acima do topo para o jogador conseguir "pegar" a escada de cima
				escada.position = Vector2(x * TAM + TAM / 2.0, inicio_y * TAM - 8)
				escada.altura = (y - inicio_y) * TAM + 8
				escada.z_index = -1
				pai.add_child(escada)
			else:
				y += 1

# ==============================================================================
# INIMIGOS (a força deles vem da configuração da fase em niveis.gd)
# ==============================================================================
func _config_inimigo(tipo: String) -> Dictionary:
	return dados.inimigos.get(tipo, {})

func _criar_inimigo(c: String, x: int, y: int) -> Node2D:
	var inimigo: Node2D
	match c:
		"o":
			var cfg := _config_inimigo("gamba")
			inimigo = CENA_GAMBA.instantiate()
			inimigo.speed = cfg.get("velocidade", 40.0)
			inimigo.max_health = cfg.get("vida", 1)
			inimigo.patrol_distance = cfg.get("patrulha", 64.0)
			inimigo.position = pe(x, y) - Vector2(0, 14)
			if cfg.has("cor"):
				inimigo.modulate = cfg.cor
		"f":
			var cfg := _config_inimigo("sapo")
			inimigo = CENA_SAPO.instantiate()
			inimigo.speed = cfg.get("velocidade", 60.0)
			inimigo.jump_force = cfg.get("pulo", -260.0)
			inimigo.jump_cooldown = cfg.get("intervalo", 2.0)
			inimigo.max_health = cfg.get("vida", 1)
			inimigo.track_player = cfg.get("persegue", false)
			inimigo.avoid_cliffs = true
			inimigo.min_jumps_per_side = 1
			inimigo.max_jumps_per_side = 2
			inimigo.position = pe(x, y) - Vector2(0, 12)
			if cfg.has("cor"):
				inimigo.modulate = cfg.cor
		"e", "h":
			var cfg := _config_inimigo("aguia")
			inimigo = CENA_AGUIA.instantiate()
			inimigo.movement_pattern = 0 if c == "e" else 1 # VERTICAL ou HORIZONTAL
			inimigo.speed = cfg.get("velocidade", 50.0)
			inimigo.patrol_distance = cfg.get("patrulha", 40.0)
			inimigo.can_dive = cfg.get("mergulha", false)
			inimigo.dive_speed = cfg.get("velocidade_mergulho", 140.0)
			inimigo.dive_cooldown = cfg.get("intervalo_mergulho", 2.5)
			inimigo.max_health = cfg.get("vida", 1)
			inimigo.position = centro(x, y)
			if cfg.has("cor"):
				inimigo.modulate = cfg.cor
		"b":
			# Morcego: usa o sprite da águia menor, roxo, voando em onda
			var cfg := _config_inimigo("morcego")
			inimigo = CENA_AGUIA.instantiate()
			inimigo.movement_pattern = 2 # SINE_HORIZONTAL
			inimigo.speed = cfg.get("velocidade", 45.0)
			inimigo.patrol_distance = cfg.get("patrulha", 48.0)
			inimigo.wave_amplitude = cfg.get("onda", 10.0)
			inimigo.wave_frequency = cfg.get("frequencia", 4.0)
			inimigo.can_dive = cfg.get("mergulha", false)
			inimigo.dive_speed = cfg.get("velocidade_mergulho", 130.0)
			inimigo.max_health = cfg.get("vida", 1)
			inimigo.modulate = cfg.get("cor", Color(0.75, 0.55, 1.0))
			inimigo.position = centro(x, y)
			_escalar(inimigo, 0.7)
	return inimigo

func _criar_chefe(x: int, y: int) -> CharacterBody2D:
	var cfg := _config_inimigo("chefe")
	var novo := CENA_GAMBA.instantiate()
	novo.set_script(SCRIPT_CHEFE)
	novo.max_health = cfg.get("vida", 8)
	novo.speed = cfg.get("velocidade", 60.0)
	novo.velocidade_investida = cfg.get("investida", 170.0)
	novo.intervalo_investida = cfg.get("intervalo", 2.6)
	novo.sonda_abismo = Vector2(28.0, 44.0)
	novo.modulate = Color(1.0, 0.75, 0.75)
	novo.position = pe(x, y) - Vector2(0, 27)
	_escalar(novo, 2.0)
	novo.vida_mudou.connect(func(atual, maximo): hud.atualizar_barra_chefe(atual, maximo))
	novo.derrotado.connect(_on_chefe_derrotado)
	return novo

# Aumenta/diminui o sprite e as formas de colisão de um inimigo
# (escalar o CharacterBody2D direto não é recomendado pelo Godot)
func _escalar(no: Node, fator: float) -> void:
	for filho in no.get_children():
		if filho is AnimatedSprite2D or filho is Sprite2D:
			filho.scale *= fator
			filho.position *= fator
		elif filho is CollisionShape2D and filho.shape:
			filho.position *= fator
			var forma: Shape2D = filho.shape.duplicate()
			if forma is RectangleShape2D:
				forma.size *= fator
			elif forma is CircleShape2D:
				forma.radius *= fator
			elif forma is CapsuleShape2D:
				forma.radius *= fator
				forma.height *= fator
			filho.shape = forma
		elif filho is Area2D:
			_escalar(filho, fator)

# ==============================================================================
# INTERFACE E REGRAS DA FASE
# ==============================================================================
func _criar_interface() -> void:
	add_child(CENA_UI_VIDA.instantiate())
	ui_pontos = CENA_UI_PONTOS.instantiate()
	add_child(ui_pontos)
	hud = HudFase.new()
	hud.idFase = idFase
	add_child(hud)
	hud.atualizar_chaves(chaves_coletadas, total_chaves)
	var plural := "chave" if total_chaves == 1 else "chaves"
	hud.mostrar_titulo(idFase, dados.nome, "Encontre %d %s para abrir a porta" % [total_chaves, plural])
	if chefe:
		hud.atualizar_barra_chefe(chefe.max_health, chefe.max_health)

func _process(_delta: float) -> void:
	# Mostra a barra do chefe quando o jogador chega perto da arena
	if is_instance_valid(chefe) and is_instance_valid(jogador) and not hud._barra_chefe.visible and chefe.health > 0:
		if jogador.global_position.distance_to(chefe.global_position) < 220.0:
			hud.mostrar_barra_chefe(true)
			hud.mensagem("Derrote o Gambá Gigante!", Color(1.0, 0.5, 0.4))

func _on_chave_coletada(chave: Chave) -> void:
	controladorFases.registrarChave(chave.idChave)
	chaves_coletadas += 1
	hud.atualizar_chaves(chaves_coletadas, total_chaves)
	if chaves_coletadas >= total_chaves:
		if porta:
			porta.destrancar()
		hud.mensagem("Todas as chaves! A porta está aberta!", Color(0.5, 1.0, 0.5))
	else:
		hud.mensagem("Chave %d/%d" % [chaves_coletadas, total_chaves], Color(1.0, 0.85, 0.3))

func _on_porta_trancada() -> void:
	var faltam := total_chaves - chaves_coletadas
	hud.mensagem("Trancada! Falta%s %d %s" % ["" if faltam == 1 else "m", faltam, "chave" if faltam == 1 else "chaves"], Color(1.0, 0.5, 0.4))

func _on_chefe_derrotado(posicao: Vector2) -> void:
	hud.mostrar_barra_chefe(false)
	hud.mensagem("O chefe deixou cair uma chave!", Color(1.0, 0.85, 0.3))
	call_deferred("_criar_chave", posicao - Vector2(0, 24), ID_CHAVE_CHEFE, _mundo.get_node("Itens"))

func _concluir_fase() -> void:
	jogador.controlavel = false
	jogador.velocity = Vector2.ZERO
	jogador.anim.play("idle")
	var tween := create_tween()
	tween.tween_property(jogador, "modulate:a", 0.0, 0.4)
	await tween.finished
	controladorFases.concluirFase(idFase)
	hud.mostrar_fase_concluida(ui_pontos.diamantes_coletados, ui_pontos.total_diamantes, idFase >= controladorFases.TOTAL_FASES)
