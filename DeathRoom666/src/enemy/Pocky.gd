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
# vars.
# -----------------------------------
var _velocity = Vector2.ZERO # 速度.
var _state = eState.APPEAR
var _timer := 0.0

# -----------------------------------
# private function.
# -----------------------------------
## 更新.
func _process(delta: float) -> void:
	
	position += _velocity * delta
	_timer += delta
	match _state:
		eState.APPEAR:
			_velocity *= 0.93 # 減衰.
			if _timer >= TIMER_APPEAR:
				# ターゲットに向かって移動.
				_state = eState.AIM
		_:
			pass
