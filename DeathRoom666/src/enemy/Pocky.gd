extends Area2D

class_name Pocky
# -----------------------------------
# 定数.
# -----------------------------------
const TIMER_APPEAR = 1.0

## 状態.
enum eState {
	APPEAR, # 出現中.
	AIM, # 目標に向かって移動.
}

# -----------------------------------
# onready.
# -----------------------------------
@onready var _spr = $Sprite2D

# -----------------------------------
# vars.
# -----------------------------------
var _state = eState.APPEAR
var _timer := 0.0
var _appear_timer := TIMER_APPEAR
var _deg := 270.0
var _speed := 100.0

# -----------------------------------
# public function.
# -----------------------------------
func set_velocity(deg:float, speed:float) -> void:
	_deg = deg
	_speed = speed
func set_appear_timer(t:float) -> void:
	_appear_timer = t
## 弾を消す.
func vanish() -> void:
	Common.start_particle(position, 1.0, Color.RED)
	queue_free()

# -----------------------------------
# private function.
# -----------------------------------
func _get_velocity() -> Vector2:
	var v = Vector2()
	var rad = deg_to_rad(_deg)
	v.x = cos(rad) * _speed
	v.y = -sin(rad) * _speed
	return v

## 更新.
func _process(delta: float) -> void:
	delta *= Common.get_bullet_time_rate()
	
	position += _get_velocity() * delta
	_timer += delta
	match _state:
		eState.APPEAR:
			# 回転する.
			var rate = (_appear_timer - _timer) / _appear_timer
			rotation_degrees += (rate * 32.0)
			_speed *= 0.95 # 減衰.
			if _timer >= _appear_timer:
				# ターゲットに向かって移動.
				_deg = Common.get_aim(position)
				_speed = 300
				_state = eState.AIM
		_:
			# 移動ベクトルは逆方向への回転なので -1
			rotation_degrees = _deg * -1


func _on_Pocky_body_entered(body: Node) -> void:
	# コリジョンレイヤー.
	var layer = body.collision_layer

	if layer & (1 << Common.eColLayer.PLAYER):
		# プレイヤーの場合は消滅処理を呼び出す.
		body.vanish()
