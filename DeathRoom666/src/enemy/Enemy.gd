extends KinematicBody2D

class_name Enemy

# --------------------------------
# preload.
# --------------------------------
const Bullet = preload("res://src/bullet/Bullet.tscn")

# --------------------------------
# 定数.
# --------------------------------
const MOVE_DECAY = 0.97 # 移動量の減衰値.
const CAMERA_OFFSET_Y = -350.0
const GRAVITY = 30
const TIMER_DEAD = 0.5

enum eState {
	MAIN,
	DEAD, # 死亡演出中.
}

# 敵のパラメータ.
const PARAMS = {
	1: {"spr": 0, "scale": 0.5, "hp": 5},
	2: {"spr": 1, "scale": 0.5, "hp": 10},
	3: {"spr": 2, "scale": 1.0, "hp": 20},
	4: {"spr": 4, "scale": 1.0, "hp": 40},
	5: {"spr": 3, "scale": 1.0, "hp": 80},
}

# --------------------------------
# exports.
# --------------------------------

# --------------------------------
# onready.
# --------------------------------
onready var _spr = $Enemy
onready var _audioHit = $AudioHit
onready var _label = $Label

# --------------------------------
# class.
# --------------------------------
class DelayedBatteryInfo:
	var deg:float = 0
	var speed:float = 0
	var delay:float = 0
	func _init(_deg:float, _speed:float, _delay:float) -> void:
		deg = _deg
		speed = _speed
		delay = _delay
	func elapse(delta:float) -> bool:
		delay -= delta
		if delay <= 0:
			return true # 発射できる.
		return false

# --------------------------------
# vars.
# --------------------------------
var _camera:Camera2D = null
var _velocity := Vector2()
var _timer := 0.0
var _target:Node2D = null
var _target_last_position = Vector2.ZERO
var _bullets:CanvasLayer = null
var _hp:int = 10
var _hp_max:int = 10
var _state = eState.MAIN
var _id:int = 0
var _batteries = [] # 弾のディレイ発射用配列.
var _cnt = 0 # 経過フレームカウンタ.
var _interval = 0

# --------------------------------
# public functions.
# --------------------------------
func is_alive() -> bool:
	return _state == eState.MAIN
	
func set_camera(camera:Camera2D) -> void:
	_camera = camera
func set_target(target:Node2D) -> void:
	_target = target
func set_bullets(bullets:CanvasLayer) -> void:
	_bullets = bullets
	
func setup(rank:int):
	_id = rank
	if not _id in PARAMS:
		init_hp(5)
		_spr.frame = (rank-1) % 5
		return
	
	var d = PARAMS[_id]
	var spr = d["spr"]
	var sc = d["scale"]
	var hp = d["hp"]
	
	_spr.frame = spr
	scale = Vector2(sc, sc)
	init_hp(hp)

## HPの初期化.
func init_hp(v:int) -> void:
	_hp = v
	_hp_max = v

## HPを減らす.
func damage(v:int) -> void:
	if _state != eState.MAIN:
		# メイン状態でなければ何もしない.
		return
	
	_audioHit.play()
	_hp -= v
	if _hp <= 0:
		_hp = 0
		# 死亡処理の開始.
		_start_dead()
		
## 消滅.
func vanish() -> void:
	Common.start_particle_enemy(position, 1, Color.white)
	Common.play_se("explosion")
	queue_free()

## HPの割合を取得する.
func hpratio() -> float:
	return 1.0 * _hp / _hp_max

# --------------------------------
# private functions.
# --------------------------------
func _ready() -> void:
	init_hp(1)

## 物理システムの更新.
func _physics_process(delta: float) -> void:
	match _state:
		eState.MAIN:
			_update_main(delta)
		eState.DEAD:
			_update_dead()

## 更新 > メイン.
func _update_main(delta:float) -> void:
	
	_velocity *= MOVE_DECAY
	
	# カメラが移動したらそれに合わせて移動する.
	var dy = (_camera.position.y + CAMERA_OFFSET_Y) - position.y
	_velocity.y = dy * 2
	
	# deltaは内部でやってくれる.
	_velocity = move_and_slide(_velocity)
	
	# 遅延発射リストの更新.
	_update_batteies(delta)

## 更新 > 死亡演出.
func _update_dead() -> void:
	_velocity.y += GRAVITY
	_velocity *= MOVE_DECAY
	
	# deltaは内部でやってくれる.
	_velocity = move_and_slide(_velocity)
	
func _start_dead() -> void:
	_state = eState.DEAD
	_timer = TIMER_DEAD * rand_range(0.7, 1.5)
	if position.x < Common.SCREEN_W/2:
		_velocity.x = 1000
	else:
		_velocity.x = -1000
	_velocity.y = -500

func _set_velocity(deg:float, speed:float) -> void:
	var rad = deg2rad(deg)
	_velocity.x = cos(rad) * speed
	_velocity.y = -sin(rad) * speed
	
## 狙い撃ち角度を取得する.
func _get_aim() -> float:
	var pos = _target_last_position
	if is_instance_valid(_target):
		pos = _target.position
		_target_last_position = pos
	
	var d = pos - position
	return rad2deg(atan2(-d.y, d.x))

## 狙い撃ち角度を取得する(yの反転なし).
func _get_aim2() -> float:
	var pos = _target_last_position
	if is_instance_valid(_target):
		pos = _target.position
		_target_last_position = pos
	
	var d = pos - position
	return rad2deg(atan2(d.y, d.x))

func _process(delta: float) -> void:
	match _state:
		eState.MAIN:
			_move_and_bullet(delta)
		eState.DEAD:
			if _audioHit.playing == false:
				_audioHit.play()
			Common.start_particle(position, 0.5, Color.white)
			_spr.rotation_degrees += 500 * delta
			_timer -= delta
			if _timer < 0:
				# 消滅.
				vanish()

func _move_and_bullet(delta) -> void:
	# この関数はフレーム固定の更新なのでこれで良い.
	_cnt += 1
		
	var prev = int(_timer * 0.5)
	_timer += delta
	var next = int(_timer * 0.5)
	if prev != next:
		var deg = 0
		if randi()%2 == 1:
			deg = 180
		_set_velocity(deg, 200)
		
	# AI関数を呼び出す.
	var aim = _get_aim()
	var ai_func = "_ai_" + str(_id)
	if has_method(ai_func):
		call(ai_func, aim)

	# 画像の回転.
	_spr.rotation_degrees = _get_aim2() - 90
	
## 弾を撃つ.
func _bullet(deg:float, speed:float, delay:float=0) -> void:
	if delay > 0.0:
		# 遅延発射なのでリストに追加するだけ.
		_add_battery(deg, speed, delay)
		return
	
	# 発射する.
	var b = Bullet.instance()
	b.position = position
	b.set_velocity(deg, speed)
	_bullets.add_child(b)

## NWayを撃つ
## @param n 発射数.
## @param center 中心角度.
## @param wide 範囲.
## @param speed 速度.
## @param delay 遅延速度.
func _nway(n, center, wide, speed, delay=0) -> void:
	if n < 1:
		return
	
	var d = wide / n
	var a = center - (d * 0.5 * (n - 1))
	for i in range(n):
		_bullet(a, speed, delay)
		a += d

## 遅延発射リストに追加する.
func _add_battery(deg:float, speed:float, delay:float) -> void:
	var b = DelayedBatteryInfo.new(deg, speed, delay)
	_batteries.append(b)

## 遅延発射リストを更新する.
func _update_batteies(delta:float) -> void:
	var tmp = []
	for b in _batteries:
		var battery:DelayedBatteryInfo = b
		if battery.elapse(delta):
			# 発射する.
			_bullet(battery.deg, battery.speed)
			continue
		
		# 発射できないのでリストに追加.
		tmp.append(b)
	
	_batteries = tmp

func _ai_1(aim:float) -> void:
	
	_label.visible = true
	_label.text = "cnt:%d\ninterval:%d"%[_cnt, _interval]
	
	if _cnt%120 == 0:
		# 2秒間隔で行動する.
		_interval += 1
	else:
		return
	
	if (_interval % 6) > 3:
		# 3回撃ったら3回休む
		return
	else:
		_nway(3, aim, 5, 100)	
	
func _ai_2(aim:float) -> void:
	if _cnt%60 == 0:
		for i in range(3):
			_nway(3, aim, 5, 100 + 20 * i, 0.02 * i)
	
func _ai_3(aim:float) -> void:
	if _cnt%60 == 0:
		for i in range(3):
			_nway(3, aim, 5, 100 + 20 * i, 0.02 * i)
	
func _ai_4(aim:float) -> void:
	if _cnt%60 == 0:
		for i in range(3):
			_nway(3, aim, 5, 100 + 20 * i, 0.02 * i)
			
func _ai_5(aim:float) -> void:
	if _cnt%60 == 0:
		for i in range(3):
			_nway(3, aim, 5, 100 + 20 * i, 0.02 * i)
