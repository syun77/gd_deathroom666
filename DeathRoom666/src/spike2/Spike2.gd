extends RigidBody2D

class_name Spike2

onready var _spr = $Sprite

var _timer:float = 0.0

# 一時停止用の保存用速度
var _linear_velocity_tmp = Vector2.ZERO

## 速度を設定する.
func set_velocity(deg:float, power:float) -> void:
	var rad = deg2rad(deg)
	var vx = cos(rad) * power
	var vy = -sin(rad) * power
	apply_central_impulse(Vector2(vx, vy))

## 消す.
func vanish() -> void:
	Common.start_particle(position, 1.0, Color.red)	
	queue_free()

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if _linear_velocity_tmp.length() != 0:
		# 保存した速度を反映.
		apply_central_impulse(_linear_velocity_tmp)
		_linear_velocity_tmp = Vector2.ZERO # ゼロにする.
	

func _physics_process(delta: float) -> void:	
	_timer += delta
	
	# アニメーション更新.
	_spr.frame = int(_timer*10) % 4


func _on_Spike2_body_entered(body: Node) -> void:
	# コリジョンレイヤー.
	var layer = body.collision_layer

	if layer & (1 << Common.eColLayer.PLAYER):
		# プレイヤーの場合は消滅処理を呼び出す.
		body.vanish()
		
		# 現在の移動量を保存しておく.
		_linear_velocity_tmp = linear_velocity
		# 逆方向に力を加えることで動きを止める.
		apply_central_impulse(-linear_velocity)
