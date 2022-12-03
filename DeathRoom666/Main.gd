extends Node2D

# ------------------------------------------
# preload.
# ------------------------------------------
const Wall = preload("res://Wall.tscn")
const Block = preload("res://Block.tscn")
const Floor = preload("res://Floor.tscn")
const EnemyObj = preload("res://src/enemy/Enemy.tscn")

# ------------------------------------------
# 定数.
# ------------------------------------------
# デバッグフラグ.
const _DEBUG = false

# カメラのスクロールオフセット.
const SCROLL_OFFSET_Y = 100.0
# 画面外のオフセット.
const OUTSIDE_OFFSET_Y = 450.0
const DBG_OUTSIDE_OFFSET_Y = 550.0
# タイマー関連.
const TIMER_HIT_STOP = 0.5 # ヒットストップ.
const TIMER_SHAKE = 0.5 # カメラ揺れ時間.

# 状態 .
enum eState {
	MAIN, # メイン.
	HIT_STOP, # ダメージストップ.
	GAMEOVER, # ゲームオーバー.
}

# カメラ揺らし種別.
enum eCameraShake {
	DISABLE, # 無効.
	VANISH_ENEMY, # 敵を倒したい.
	GAMEOVER, # ゲームオーバー.
}

# ------------------------------------------
# onready
# ------------------------------------------
onready var _main_layer = $MainLayer
onready var _block_layer = $WallLayer
onready var _player = $MainLayer/Player
onready var _camera = $MainCamera
onready var _enemy_layer = $EnemyLayer
onready var _shot_layer = $ShotLayer
onready var _bullet_layer = $BulletLayer
onready var _effect_layer = $EffectLayerFront
onready var _labelScore = $UILayer/LabelScore
onready var _ui_gameover = $UILayer/Gameover
onready var _healthBar = $UILayer/ProgressBar

# ------------------------------------------
# vars.
# ------------------------------------------
var _state = eState.MAIN
var _timer = 0.0
var _timer_prev = 0.0
var _enemy:Enemy = null
var _enemy_rank = 0 # 敵のランク.
var _enemy_pos_y = 0 # 敵が出現した座標.
# カメラ用.
var _camera_x_prev = 0.0
var _camera_shake_type = eCameraShake.DISABLE
var _camera_shake_position = Vector2.ZERO
var _camera_shake_timer = 0.0

# ------------------------------------------
# private functions.
# ------------------------------------------
func _ready() -> void:
	#OS.set_window_size(Vector2(160, 300))
	
	# ランダムに足場を作る
	_create_random_floor()
	
	# セットアップ.
	var layers = {
		"enemy": _enemy_layer,
		"shot": _shot_layer,
		"bullet": _bullet_layer,
		"effect": _effect_layer,
	}
	Common.setup(layers)

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
	
	match _state:
		eState.MAIN:
			_update_main(delta)
		eState.HIT_STOP:
			_update_hit_stop(delta)
		eState.GAMEOVER:
			_update_gameover(delta)

	# カメラ揺れの更新.
	_update_camera_shake(delta)

## 更新 > メイン.
func _update_main(delta:float) -> void:
	
	# プレイヤー死亡チェック.
	if is_instance_valid(_player) == false or _player.is_request_dead():
		_state = eState.HIT_STOP
		_timer = TIMER_HIT_STOP
		_enter_hit_stop()
		return
		
	_timer += delta
	_update_camera()	
	_check_block()
	_check_outside()
	_update_enemy_hp()

## 更新 > ヒットストップ.
func _update_hit_stop(delta:float) -> void:
	
	if is_instance_valid(_player):
		# ダメージアニメ更新.
		_player.update_damage()
	
	_timer -= delta
	if _timer <= 0:
		# そして時は動き出す...
		_set_process_all_objects(true)
		_enter_gameover()
		_state = eState.GAMEOVER

## 更新 > ゲームオーバー.
func _update_gameover(delta:float) -> void:
	_ui_gameover.visible = true	
	_camera.position = _camera_shake_position
	
	if Input.is_action_just_pressed("act_jump"):
		# リスタート.
		get_tree().change_scene("res://Main.tscn")

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
			var next_y = next * Common.TILE_SIZE - 424 + 12
			for x in [Common.TILE_HALF, 480.0 - Common.TILE_HALF]:
				var wall = Wall.instance()
				wall.position.x = x
				wall.position.y = next_y
				_block_layer.add_child(wall)
				
			# ランダムで足場も作っておきます.
			if randi()%3 == 0:
				_random_floor(next_y)

			# 敵の出現チェック.			
			_check_appear_enemy(next, next_y)
			
		_camera_x_prev = target_y
	
## ランダムで足場を作る
func _random_floor(next_y:float) -> void:
	var idx = randi()%(8-5) + 1
	for j in range(2):
		var floor_obj = Floor.instance()
		floor_obj.position.x = _block_x(idx+j)
		floor_obj.position.y = next_y
		_block_layer.add_child(floor_obj)
	
## ブロックの出現.
func _check_block() -> void:
	var interval = 1.0
	var prev = int(_timer_prev * interval)
	var next = int(_timer * interval)
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
	_block_layer.add_child(block)
	
	# TODO: ランダムで速度を設定.
	match randi()%20:
		0:
			block.set_max_velocity_y(50)
		1:
			block.set_max_velocity_y(200)
		2:
			block.set_max_velocity_y(300)
		_:
			pass

## 画面外チェック.
func _check_outside() -> void:
	# 画面外とする位置
	var outside_top_y = _camera.position.y - OUTSIDE_OFFSET_Y
	var outside_y = _camera.position.y + OUTSIDE_OFFSET_Y
	
	# 画面外の壁を消す.
	for block in _block_layer.get_children():
		if block.position.y > outside_y:
			# 画面外なので消す.
			block.queue_free()
	
	for shot in _shot_layer.get_children():
		if not shot is Area2D:
			continue # shotはArea2Dのみ
		var py = shot.position.y
		if py < outside_top_y or py > outside_y:
			# 画面外なので消す.
			shot.queue_free()
	
	for bullet in _bullet_layer.get_children():
		var py = bullet.position.y
		if py < outside_top_y or py > outside_y:
			# 画面外なので消す.
			bullet.queue_free()
	
	# プレイヤー死亡判定.
	if _player.position.y > outside_y:
		_player.vanish()

## 敵HPバーの更新.
func _update_enemy_hp() -> void:
	if is_instance_valid(_enemy) == false:
		_healthBar.visible = false # ゲージを消します
		return
	
	_healthBar.visible = true # ゲージを出現させます.
	var rate = _enemy.hpratio()
	_healthBar.value = 100 * rate

## ヒットストップ開始.
func _enter_hit_stop():
	# オブジェクトの動きをすべて止める.
	_set_process_all_objects(false)

## ゲームオーバー開始.
func _enter_gameover():	
	# カメラ揺らし開始.
	_start_camera_shake(eCameraShake.GAMEOVER)
	
	# スムージングを無効化.
	_camera.smoothing_enabled = false

## カメラ揺らしの開始.
func _start_camera_shake(type:int) -> void:
	# カメラ位置を保持.
	_camera_shake_type = type
	_camera_shake_position = _camera.position
	_camera_shake_timer = TIMER_SHAKE

func _set_process_all_objects(b:bool) -> void:
	for obj in _main_layer.get_children():
		obj.set_process(b)
		obj.set_physics_process(b)
	for wall in _block_layer.get_children():
		wall.set_process(b)
		wall.set_physics_process(b)
	for bullet in _bullet_layer.get_children():
		bullet.set_process(b)

## 更新 > カメラ揺らし
func _update_camera_shake(delta:float) -> void:
	if _camera_shake_type == eCameraShake.DISABLE:
		return # 無効なので何もしない.
		
	# カメラを揺らす.
	var w = 64 # 幅
	var h = 16 # 高さ
	
	match _camera_shake_type:
		eCameraShake.VANISH_ENEMY:
			w = 32
			h = 8
		eCameraShake.GAMEOVER:
			w = 64
			h = 16
	
	var rate = _camera_shake_timer / TIMER_SHAKE
	var dx = rand_range(-w, w) * rate
	var dy = rand_range(-h, h) * rate
	_camera.position = _camera_shake_position + Vector2(dx, dy)
	_camera_shake_timer -= delta
	if _camera_shake_timer <= 0.0:
		# 揺れ終了.
		_camera_shake_type = eCameraShake.DISABLE

## 敵の出現チェック.
func _check_appear_enemy(next:int, next_y:float) -> void:
	if _enemy_rank == 0:
		if next < -2:
			# 最初の敵が出現.
			_enemy_rank += 1
			_appear_enemy(next_y)
		return
	
	if is_instance_valid(_enemy):
		# 出現中の場合は位置だけ記憶しておく.
		_enemy_pos_y = next
		return
	
	# 存在しないので出現させる.	
	if next < _enemy_pos_y - 16:
		# 前回よりも16以上進むと次の敵が出現する.
		_enemy_rank += 1
		_appear_enemy(next_y)

## 敵の初期化.
func _init_enemy(enemy) -> void:
	enemy.set_target(_player)
	enemy.set_camera(_camera)
	enemy.set_bullets(_bullet_layer)

## 敵の出現.
func _appear_enemy(next_y:float) -> void:	
	_enemy = EnemyObj.instance()
	_enemy.position.x = Common.SCREEN_W/2
	_enemy.position.y = next_y
	# 初期化.
	_init_enemy(_enemy)
	
	_enemy_layer.add_child(_enemy)
	# セットアップ.
	_enemy.setup(_enemy_rank)

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
