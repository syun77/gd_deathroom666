extends Area2D
# =================================
# 爆発する弾 (接触ダメージなし).
# =================================
class_name Bomber

# ---------------------------------
# 定数.
# ---------------------------------
const TIMER = 1.0

# ---------------------------------
# vars.
# ---------------------------------
var _timer := 0.0
var _start_pos := Vector2.ZERO
var _target_pos := Vector2.ZERO

# ---------------------------------
# public functions.
# ---------------------------------
## 開始座標を設定.
func set_pos(start:Vector2, end:Vector2) -> void:
	position = start
	_start_pos = start

# ---------------------------------
# private functions.
# ---------------------------------
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_timer += delta
	var rate = _ease(_timer/TIMER)
	if rate > 1.0:
		rate = 1.0
	var d = _target_pos - _start_pos
	position = _start_pos + (d * rate)
	if rate >= TIMER:
		# 終了.
		queue_free()
		
func _ease(t:float) -> float:
	# Cubic in.
	return t * t * t
