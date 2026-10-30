@tool
extends AnimatableBody2D

@export var speed: float = 80.0
@export var distance: float = 128

@export var direction: Vector2 = Vector2.RIGHT
@export var wait_time: float = 0.0
@export var loop: bool = true

var _origin: Vector2
var _destination: Vector2 
var _forward := true 
var _waiting := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_origin = global_position 
	_destination = _origin + direction.normalized() * distance
	#Direction(1,0) = horizontal, (0,-1) = vertical e (1,-1) = diagonal
	
	queue_redraw()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): # para os tools ficar so no editor
		return
	
	if _waiting:
		return
		
	var target := _destination if _forward else _origin
	
	global_position = global_position.move_toward(target, speed * delta)
	
	if global_position == target: 
		if not loop: # se voce quiser que ela pare
			return
			
		if wait_time > 0:
			_wait()
		else:
			_forward = !_forward #Togul vai e volta da plataforma
	if Engine.is_editor_hint():
		queue_redraw()

func _wait() -> void:
	_waiting = true
	
	await get_tree().create_timer(wait_time).timeout
	
	_waiting = false
	_forward = !_forward

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
		
	var dir := direction.normalized()
	var target := dir * distance
	
	# Metodos da funçao _draw
	draw_dashed_line(Vector2.ZERO, target, Color(0.537, 0.118, 0.0, 0.8), 2.0, 6.0)
	draw_circle(Vector2.ZERO, 5.0, Color(0.111, 0.462, 0.506, 1.0))
	
	draw_circle(target, 7.0, Color(0.537, 0.118, 0.0, 1.0))
	
	var cross_size := 10.0
	draw_line(target + Vector2(-cross_size, 0), target + Vector2(cross_size, 0), Color(0.537, 0.118, 0.0, 1.0))
	draw_line(target + Vector2(0, -cross_size), target + Vector2(0, cross_size), Color(0.537, 0.118, 0.0, 1.0))
