extends Area2D

onready var _spr = $Bullet

var _velocity = Vector2()


func set_velocity(deg:float, speed:float) -> void:
	var rad = deg2rad(deg)
	_velocity.x = cos(rad) * speed
	_velocity.y = -sin(rad) * speed

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	position += _velocity * delta;
	
	# 画像の回転.
	rotation = atan2(_velocity.y, _velocity.x)

func _on_Bullet_body_entered(body: Node) -> void:
	# 衝突対象とするレイヤー.
	var tbl = [0, 1]
	var layer = body.collision_layer
	var is_find = false
	for id in tbl:
		if layer & (1 << id):
			is_find = true
			break
	if is_find == false:
		return
		
	if body.collision_layer & (1 << 1):
		if not "Wall" in body.name:
			return # "Wall" 以外は衝突しないことにします

	# 何かに衝突したら消える.
	queue_free()
