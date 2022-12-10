extends Area2D
# =================================
# 爆発する弾 (接触ダメージなし).
# =================================
class_name Bomber

const BlastObj = preload("res://src/bullet/Blast.tscn")
# ---------------------------------
# 定数.
# ---------------------------------
const TIMER = 1.0
# ---------------------------------
# onready.
# ---------------------------------
onready var _snd = $AudioStreamPlayer2D

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
	_target_pos = end

func vanish() -> void:
	queue_free()

# ---------------------------------
# private functions.
# ---------------------------------
func _ready() -> void:
	_snd.play()

func _process(delta: float) -> void:
	delta *= Common.get_bullet_time_rate()

	_timer += delta
	var rate = _back_in(_timer/TIMER)
	if rate > 1.0:
		rate = 1.0
	var d = _target_pos - _start_pos
	position = _start_pos + (d * rate)
	if rate >= TIMER:
		# 終了.
		var bullets = Common.get_layer("bullet")
		var blast = BlastObj.instance()
		blast.position = position
		bullets.add_child(blast)

		vanish()
		
func _cube_in(t:float) -> float:
	# cubic in.
	return t * t * t

func _back_in(t:float) -> float:
	# back in.
	return t * t * (2.70158 * t - 1.70158)
