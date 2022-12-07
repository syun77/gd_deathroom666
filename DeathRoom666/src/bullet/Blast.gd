extends Area2D
# =================================
# 爆風 (接触ダメージあり).
# =================================

class_name Blast

# ---------------------------------
# 定数.
# ---------------------------------
const TIMER = 1.0 # 拡大・縮小時間.

# ---------------------------------
# vars.
# ---------------------------------
var _timer = 0.0

# ---------------------------------
# public functions.
# ---------------------------------

# ---------------------------------
# private functions.
# ---------------------------------
func _process(delta: float) -> void:
	_timer = delta
	var sc = sin(_timer * PI) # 0(0度) -> 1(90度) -> 0 (180度)
	scale = Vector2(sc, sc)
	