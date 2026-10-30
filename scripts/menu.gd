class_name menuPrincipal
extends Control

# Controla o menu principal

# Botões
func _on_jogar_pressed() -> void:
	controladorFases.carregarFase(0)
	desativar()
func _on_sair_pressed() -> void:
	get_tree().quit()

# Funções para controlar o menu
func desativar() -> void:
	hide()
	set_process(false)
	set_physics_process(false)
	set_process_unhandled_input(false)
	set_process_input(false)
func ativar() -> void:
	show()
	set_process(true)
	set_physics_process(true)
	set_process_unhandled_input(true)
	set_process_input(true)
