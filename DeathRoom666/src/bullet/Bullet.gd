extends Area2D

onready var _spr = $Bullet

# 移動速度.
var _velocity = Vector2()

## 移動量を設定する.
func set_velocity(deg:float, speed:float) -> void:
	var rad = deg2rad(deg)
	_velocity.x = cos(rad) * speed
	_velocity.y = -sin(rad) * speed

## 弾を消す.
func vanish() -> void:
	queue_free()

func _ready() -> void:
	pass

func _process(delta: float) -> void:
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
