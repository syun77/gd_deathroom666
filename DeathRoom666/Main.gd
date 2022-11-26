extends Node2D

const Block = preload("res://Block.tscn")

var _timer = 0.0
var _timer_prev = 0.0

onready var _block_layer = $WallLayer

func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	_debug()
	
	_timer += delta
	
	_check_block()
	
func _check_block() -> void:
	var prev = int(_timer_prev)
	var next = int(_timer)
	if prev != next:
		_appear_block()
	_timer_prev = _timer
	
func _appear_block() -> void:
	var block = Block.instance()
	block.position.x = (1.5 + randi()%8) * 48.0
	block.position.y = (-48.0)
	block.set_parent(_block_layer)
	_block_layer.add_child(block)
	
func _debug() -> void:
	if Input.is_action_just_pressed("ui_reset"):
		get_tree().change_scene("res://Main.tscn")
