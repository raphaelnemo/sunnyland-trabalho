class_name PortaTrancada
extends Area2D

# Porta de saída da fase. Fica trancada até o jogador pegar todas as chaves.
# Com a porta aberta, o jogador aperta CIMA (W / seta) para entrar.

signal jogador_entrou
signal tentou_abrir_trancada

const TEX_FECHADA := preload("res://assets/environment/props/door.png")
const TEX_ABERTA := preload("res://assets/environment/props/door-opened.png")
const TEX_CADEADO := preload("res://assets/misc/novos/cadeado.png")

var trancada: bool = true
var jogador_na_porta: bool = false
var usada: bool = false

var _sprite: Sprite2D
var _cadeado: Sprite2D
var _aviso: Label
var _tempo: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	z_index = -1

	_sprite = Sprite2D.new()
	_sprite.texture = TEX_FECHADA
	_sprite.offset = Vector2(0, -TEX_FECHADA.get_height() / 2.0)
	add_child(_sprite)

	_cadeado = Sprite2D.new()
	_cadeado.texture = TEX_CADEADO
	_cadeado.position = Vector2(0, -16)
	add_child(_cadeado)

	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(20, 30)
	forma.shape = retangulo
	forma.position = Vector2(0, -15)
	add_child(forma)

	_aviso = Label.new()
	_aviso.add_theme_font_size_override("font_size", 8)
	_aviso.add_theme_color_override("font_outline_color", Color.BLACK)
	_aviso.add_theme_constant_override("outline_size", 3)
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.size = Vector2(60, 12)
	_aviso.position = Vector2(-30, -48)
	_aviso.visible = false
	add_child(_aviso)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func destrancar() -> void:
	if not trancada:
		return
	trancada = false
	_sprite.texture = TEX_ABERTA
	var tween := create_tween()
	tween.tween_property(_cadeado, "position:y", -40.0, 0.4)
	tween.parallel().tween_property(_cadeado, "modulate:a", 0.0, 0.4)
	_aviso.text = "▲ Entrar"
	_aviso.visible = jogador_na_porta

func _process(delta: float) -> void:
	_tempo += delta
	if _aviso.visible:
		_aviso.position.y = -48 + sin(_tempo * 6.0) * 1.5
	if trancada:
		_cadeado.position.y = -16 + sin(_tempo * 4.0) * 1.0

	if jogador_na_porta and not usada and _apertou_cima():
		if trancada:
			tentou_abrir_trancada.emit()
		else:
			usada = true
			_aviso.visible = false
			jogador_entrou.emit()

func _apertou_cima() -> bool:
	for acao in ["up", "ui_up", "cima"]:
		if InputMap.has_action(acao) and Input.is_action_just_pressed(acao):
			return true
	return false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		jogador_na_porta = true
		_aviso.text = "Trancada" if trancada else "▲ Entrar"
		_aviso.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		jogador_na_porta = false
		_aviso.visible = false
