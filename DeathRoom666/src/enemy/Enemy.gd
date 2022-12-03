extends KinematicBody2D

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

# --------------------------------
# exports.
# --------------------------------

# --------------------------------
# exports.
# --------------------------------
onready var _spr = $Enemy

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

## HPの初期化.
func init_hp(v:int) -> void:
	_hp = v
	_hp_max = v

## HPを減らす.
func damage(v:int) -> void:
	if _state != eState.MAIN:
		# メイン状態でなければ何もしない.
		return
		
	_hp -= v
	if _hp <= 0:
		_hp = 0
		# 死亡処理の開始.
		_start_dead()
		
## 消滅.
func vanish() -> void:
	Common.start_particle_enemy(position, 1, Color.white)
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
func _physics_process(_delta: float) -> void:
	match _state:
		eState.MAIN:
			_update_main()
		eState.DEAD:
			_update_dead()

## 更新 > メイン.
func _update_main() -> void:
	_velocity *= MOVE_DECAY
	
	# カメラが移動したらそれに合わせて移動する.
	var dy = (_camera.position.y + CAMERA_OFFSET_Y) - position.y
	_velocity.y = dy * 2
	
	# deltaは内部でやってくれる.
	_velocity = move_and_slide(_velocity)

## 更新 > 死亡演出.
func _update_dead() -> void:
	_velocity.y += GRAVITY
	_velocity *= MOVE_DECAY
	
	# deltaは内部でやってくれる.
	_velocity = move_and_slide(_velocity)
	
func _start_dead() -> void:
	_state = eState.DEAD
	_timer = TIMER_DEAD
	if position.x < Common.SCREEN_W/2:
		_velocity.x = 1000
	else:
		_velocity.x = -1000

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
			Common.start_particle(position, 0.5, Color.white)
			_spr.rotation_degrees += 500 * delta
			_timer -= delta
			if _timer < 0:
				# 消滅.
				vanish()

func _move_and_bullet(delta) -> void:			
	var prev = int(_timer * 0.5)
	_timer += delta
	var next = int(_timer * 0.5)
	if prev != next:
		var deg = 0
		if randi()%2 == 1:
			deg = 180
		_set_velocity(deg, 200)
		
		var aim = _get_aim()
		_bullet(aim-2, 300)
		_bullet(aim, 300)
		_bullet(aim+2, 300)

	# 画像の回転.
	_spr.rotation_degrees = _get_aim2()
	
## 弾を撃つ.
func _bullet(deg:float, speed:float, ofs:Vector2 = Vector2.ZERO) -> void:
	var b = Bullet.instance()
	b.position = position + ofs
	b.set_velocity(deg, speed)
	_bullets.add_child(b)
