extends Area2D

class_name Spike2

onready var _spr = $Sprite

var _timer:float = 0.0
var _velocity = Vector2.ZERO

## 速度を設定する.
func set_velocity(deg:float, power:float) -> void:
	var rad = deg2rad(deg)
	_velocity.x = cos(rad) * power
	_velocity.y = -sin(rad) * power

## 消す.
func vanish() -> void:
	Common.start_particle(position, 1.0, Color.red)	
	queue_free()

func _ready() -> void:
	_spr.frame = 1 # 大根ミサイル.

func _process(delta: float) -> void:
	delta *= Common.get_bullet_time_rate()
	position += _velocity * delta
	
	var left = Common.TILE_SIZE * 1.5
	var right = Common.SCREEN_W - Common.TILE_SIZE * 1.5
	if position.x < left:
		position.x = left
		_velocity.x *= -1
	if position.x > right:
		position.x = right
		_velocity.x *= -1
	
	_spr.rotation = atan2(_velocity.y, _velocity.x)

func _physics_process(delta: float) -> void:
	_timer += delta

func _on_Spike2_body_entered(body: Node) -> void:
	# コリジョンレイヤー.
	var layer = body.collision_layer

	if layer & (1 << Common.eColLayer.PLAYER):
		# プレイヤーの場合は消滅処理を呼び出す.
		body.vanish()
