extends Area2D

onready var _spr = $Bullet

# 移動速度.
var _velocity = Vector2()
# 加速度.
var _accel = Vector2()

## 移動量を設定する.
func set_velocity(deg:float, speed:float) -> void:
	var rad = deg2rad(deg)
	_velocity.x = cos(rad) * speed
	_velocity.y = -sin(rad) * speed
	
func set_accel(ax:float, ay:float) -> void:
	_accel.x = ax
	_accel.y = ay

## 移動量を取得する.
func get_velocity() -> Vector2:
	return _velocity

## 弾を消す.
func vanish() -> void:
	Common.start_particle(position, 1.0, Color.red)
	
	queue_free()

func _ready() -> void:
	_spr.modulate = Color.salmon

func _process(delta: float) -> void:
	_velocity += _accel
	position += _velocity * delta;
	
	# 画像の回転.
	rotation = atan2(_velocity.y, _velocity.x)

func _on_Bullet_body_entered(body: CollisionObject2D) -> void:
	# 衝突対象とするレイヤー.
	var tbl = [Common.eColLayer.PLAYER, Common.eColLayer.WALL]
	var layer = body.collision_layer
	var is_find = false
	for id in tbl:
		if layer & (1 << id):
			is_find = true
			break
	if is_find == false:
		return
		
	if layer & (1 << Common.eColLayer.WALL):
		if not "Wall" in body.name:
			return # "Wall" 以外は衝突しないことにします

	if layer & (1 << Common.eColLayer.PLAYER):
		# プレイヤーの場合は消滅処理を呼び出す.
		body.vanish()

	# 何かに衝突したら消える.
	vanish()
