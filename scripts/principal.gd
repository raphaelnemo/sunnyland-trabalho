extends Node

@export var fasesDisponiveis : Array[dadosFase]
@onready var node_2d: Node2D = $Node2D

func _ready() -> void:
	controladorFases.principal = node_2d
	controladorFases.fasesDisponiveis = fasesDisponiveis
	controladorFases.carregarProgresso()
