extends Area2D
# =============================
# 照準オブジェクト.
# =============================
class_name Reticle

# -----------------------------
# 定数.
# -----------------------------
const INIT_SPEED = 500.0 # 初速.
const MAX_SPEED  = 200.0 # 最高速度.
const TIME_SHOOT = 0.5 # 0.5秒で発射する.
const TIMEOUT = 3.0 # 3秒でタイムアウト.

enum eState {
	MAIN,
	STOP,
}

# -----------------------------
# onready.
# -----------------------------
onready var _spr = $Sprite
onready var _label = $Label
onready var _snd = $AudioStreamPlayer2D

# -----------------------------
# vars.
# -----------------------------
# 状態.
var _state = eState.MAIN
# プレイヤーにヒットしているかどうか.
var _is_hit := false
var _bomber:Bomber = null

# 移動速度.
var _deg := 270
var _speed := 300

# 経過時間.
var _timer := 0.0
# 照準が重なっている時間.
var _aim_time := 0.0
var _aim_cnt = 0

# -----------------------------
# public function.
# -----------------------------
## プレイヤーと衝突しているかどうか.
func is_hit() -> bool:
	return _is_hit

func can_shoot() -> bool:
	if _state == eState.STOP:
		return false # もう撃てない.
	
	# タイムアウトチェック.
	if _timer >= TIMEOUT:
		return true
	# 一定時間重なっていたら爆弾を発射する.
	return _aim_time >= TIME_SHOOT

## 経過時間を取得する.
func get_past_time() -> float:
	return _timer

## 消滅.
func vanish() -> void:
	queue_free()
	
func start_bomber(bomber) -> void:
	_state = eState.STOP
	_bomber = bomber

# -----------------------------
# private function.
# -----------------------------
## 更新.
func _process(delta: float) -> void:
	# デバッグ用.
	#_label.text = "TIME: %3.2f\nAIM: %3.2f\nSPEED:%3.2f"%[_timer, _aim_time, _speed]

	match _state:
		eState.MAIN:
			_update_main(delta)
		eState.STOP:
			_update_stop()	

func _update_main(delta:float) -> void:
	if _speed > MAX_SPEED:
		# 最高速度を超えていたら減速する.
		_speed -= 1 * delta
	
	if _is_hit:
		_aim_time += delta
	else:
		# リセットしない
		#_aim_time = 0.0
		_aim_cnt = 0
	
	_timer += delta
	var t = int(_timer * 20)	
	if _is_hit and (t % 2 == 0):
		_spr.modulate = Color.red
	else:
		_spr.modulate = Color.yellow

	# プレイヤーめがけて移動する.
	var aim = Common.get_aim(position)
	var d = Common.diff_angle(_deg, aim)
	_deg += d * 0.03
	
	# 速度を加算.
	position += _get_vector() * delta
	
func _update_stop() -> void:
	_spr.modulate = Color.red
	if is_instance_valid(_bomber) == false:
		# 爆弾が消えたら消えます.
		vanish()

func _get_vector() -> Vector2:
	var v = Vector2()
	var rad = deg2rad(_deg)
	v.x = cos(rad) * _speed
	v.y = -sin(rad) * _speed
	return v

func _physics_process(_delta: float) -> void:
	if _state == eState.MAIN:
		if _is_hit:
			_aim_cnt += 1
			if _aim_cnt%8 == 1:
				_snd.play()

func _on_Reticle_body_entered(body: Node) -> void:
	var layer = body.collision_layer
	if layer & (1 << Common.eColLayer.PLAYER):
		# プレイヤーと衝突.
		_is_hit = true

func _on_Reticle_body_exited(body: Node) -> void:
	var layer = body.collision_layer
	if layer & (1 << Common.eColLayer.PLAYER):
		# プレイヤーとの衝突が失われた..
		_is_hit = false
