extends Node2D

const Wall = preload("res://Wall.tscn")
const Block = preload("res://Block.tscn")

var _timer = 0.0
var _timer_prev = 0.0
var _camera_x_prev = 0.0

onready var _block_layer = $WallLayer
onready var _player = $Player
onready var _camera = $MainCamera

func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	_debug()
	
	_timer += delta
	_update_camera()	
	_check_block()

## カメラの更新.
func _update_camera() -> void:
	var target_y = _player.position.y - 200
	if target_y < _camera.position.y:
		var prev = int(_camera_x_prev / 48.0)
		var next = int(target_y / 48.0)
		
		# スクロール開始.
		_camera.position.y = target_y
		
		# 横壁を作る.
		if prev != next:
			for x in [24.0, 480.0 - 24.0]:
				var wall = Wall.instance()
				wall.position.x = x
				wall.position.y = next * 48.0 - 424 + 12
				_block_layer.add_child(wall)
		_camera_x_prev = target_y
	
	# 画面外の壁を消す.
	# 画面外とする位置
	var outside_y = _camera.position.y + 500
	
	for block in _block_layer.get_children():
		if block.position.y > outside_y:
			# 画面外なので消す.
			block.queue_free()	
	
## ブロックの出現.
func _check_block() -> void:
	var prev = int(_timer_prev)
	var next = int(_timer)
	if prev != next:
		_appear_block()
	_timer_prev = _timer
	
func _appear_block() -> void:
	var block = Block.instance()
	block.position.x = (1.5 + randi()%8) * 48.0
	block.position.y = _camera.position.y - 424
	block.set_parent(_block_layer)
	match randi()%20:
		0:
			block.set_max_velocity_y(50)
		1:
			block.set_max_velocity_y(200)
		2:
			block.set_max_velocity_y(300)
	
	_block_layer.add_child(block)
	
func _debug() -> void:
	if Input.is_action_just_pressed("ui_reset"):
		get_tree().change_scene("res://Main.tscn")

	# 画面外ジャンプ.
	if _player.position.y > _camera.position.y + 550:
		_player._velocity.y = -1000
