class_name fase
extends Node

# Atrela uma fase a um id

@export var idFase : int
var dadoFase : dadosFase

func _ready() -> void:
	dadoFase = controladorFases.carregarDados(idFase)
