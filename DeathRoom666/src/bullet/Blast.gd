extends Area2D
# =================================
# 爆風 (接触ダメージあり).
# =================================

class_name Blast

# ---------------------------------
# 定数.
# ---------------------------------
const TIMER = 0.5 # 拡大・縮小時間.

# ---------------------------------
# onready.
# ---------------------------------
@onready var _snd = $AudioStreamPlayer2D

# ---------------------------------
# vars.
# ---------------------------------
var _timer = 0.0

# ---------------------------------
# public functions.
# ---------------------------------
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
	var rate = back_out(1.0 - _timer / TIMER)
	#var sc = sin(rate * PI) # 0(0度) -> 1(90度) -> 0 (180度)
	var sc = 0.5 + rate
	scale = Vector2(sc, sc)
	
	if _timer >= TIMER:
		queue_free()
		
func _back_in(t:float) -> float:
	# back in.
	return t * t * (2.70158 * t - 1.70158)
func back_out(t:float) -> float:
	return 1 - (t - 1) * (t-1) * (-2.70158 * (t-1) - 1.70158)	
	
func _on_Blast_body_entered(body: Node) -> void:
	var layer = body.collision_layer
	if layer & (1 << Common.eColLayer.PLAYER):
		# プレイヤーと衝突.
		body.vanish()
