extends Node2D

# ------------------------------------------
# preload.
# ------------------------------------------
const Wall = preload("res://Wall.tscn")
const Block = preload("res://Block.tscn")
const Floor = preload("res://Floor.tscn")

# ------------------------------------------
# 定数.
# ------------------------------------------
# デバッグフラグ.
const _DEBUG = false

# カメラのスクロールオフセット.
const SCROLL_OFFSET_Y = 100.0
# 画面外のオフセット.
const OUTSIDE_OFFSET_Y = 500.0
const DBG_OUTSIDE_OFFSET_Y = 550.0

# 状態 .
enum eState {
	MAIN, # メイン.
	GAMEOVER, # ゲームオーバー.
}

# ------------------------------------------
# onready
# ------------------------------------------
onready var _block_layer = $WallLayer
onready var _player = $MainLayer/Player
onready var _camera = $MainCamera
onready var _enemy = $MainLayer/Enemy
onready var _bullet_layer = $BulletLayer
onready var _labelScore = $UILayer/LabelScore
onready var _labelCaption = $UILayer/LabelCaption

# ------------------------------------------
# vars.
# ------------------------------------------
var _state = eState.MAIN
var _timer = 0.0
var _timer_prev = 0.0
var _camera_x_prev = 0.0

# ------------------------------------------
# private functions.
# ------------------------------------------
func _ready() -> void:
	_enemy.set_target(_player)
	_enemy.set_camera(_camera)
	_enemy.set_bullets(_bullet_layer)
	
	# ランダムに足場を作る
	_create_random_floor()

## ランダムに足場を作る
func _create_random_floor():
	for i in range(4):
		var idx = randi()%(8-3)
		for j in range(3):
			var floor_obj = Floor.instance()
			floor_obj.position.x = _block_x(idx+j)
			floor_obj.position.y = (1.5 + i * 4) * Common.TILE_SIZE
			_block_layer.add_child(floor_obj)

## 更新
func _process(delta: float) -> void:
	_debug()
	
	_timer += delta
	_update_camera()	
	_check_block()

## カメラの更新.
func _update_camera() -> void:
	var target_y = _player.position.y - SCROLL_OFFSET_Y
	if target_y < _camera.position.y:
		var prev = int(_camera_x_prev / Common.TILE_SIZE)
		var next = int(target_y / Common.TILE_SIZE)
		
		# スクロール開始.
		_camera.position.y = target_y
		
		# 横壁を作る.
		if prev != next:
			for x in [Common.TILE_HALF, 480.0 - Common.TILE_HALF]:
				var wall = Wall.instance()
				wall.position.x = x
				wall.position.y = next * Common.TILE_SIZE - 424 + 12
				_block_layer.add_child(wall)
		_camera_x_prev = target_y
	
	# 画面外の壁を消す.
	# 画面外とする位置
	var outside_top_y = _camera.position.y - OUTSIDE_OFFSET_Y
	var outside_y = _camera.position.y + OUTSIDE_OFFSET_Y
	
	for block in _block_layer.get_children():
		if block.position.y > outside_y:
			# 画面外なので消す.
			block.queue_free()
	
	for bullet in _bullet_layer.get_children():
		var py = bullet.position.y
		if py < outside_top_y or py > outside_y:
			# 画面外なので消す.
			bullet.queue_free()
	
## ブロックの出現.
func _check_block() -> void:
	var prev = int(_timer_prev)
	var next = int(_timer)
	if prev != next:
		_appear_block()
	_timer_prev = _timer
	
func _block_x(idx:int=-1) -> float:
	if idx < 0:
		idx = randi()%8
	return (1.5 + idx) * Common.TILE_SIZE

## ブロックの出現.
func _appear_block() -> void:
	var block = Block.instance()
	block.position.x = _block_x()
	block.position.y = _camera.position.y - 424
	block.set_parent(_block_layer)
	# TODO: ランダムで速度を設定.
	match randi()%20:
		0:
			block.set_max_velocity_y(50)
		1:
			block.set_max_velocity_y(200)
		2:
			block.set_max_velocity_y(300)
	
	_block_layer.add_child(block)


# ------------------------------------------
# debug functions.
# ------------------------------------------

func _debug() -> void:
	if Input.is_action_just_pressed("ui_reset"):
		get_tree().change_scene("res://Main.tscn")

	if _DEBUG:
		if is_instance_valid(_player):
			# 画面外ジャンプ.
			if _player.position.y > _camera.position.y + DBG_OUTSIDE_OFFSET_Y:
				_player._velocity.y = -1500
