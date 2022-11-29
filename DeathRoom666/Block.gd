extends KinematicBody2D

#const Wall = preload("res://Wall.tscn")
const Wall = preload("res://Floor.tscn")

const GRAVITY = 40
const DEFAULT_MAX_VELOCITY = 100

var _parent:CanvasLayer = null
var _velocity = Vector2()
var _freezed = false
var _max_velocity_y = DEFAULT_MAX_VELOCITY

func set_max_velocity_y(dy:float) -> void:
	_max_velocity_y = dy

func freeze() -> void:
	if _freezed:
		return # フリーズ済み.
	
	_freezed = true
	# 固定ブロックにする
	queue_free()
	var wall = Wall.instance()
	position.y -= 48.0 # 1タイルぶんずれる.
	wall.position = position
	_parent.add_child(wall)
		
func set_parent(layer:CanvasLayer) -> void:
	_parent = layer

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	# 重力を加算
	_velocity.y += GRAVITY
	_velocity.y = min(_velocity.y, _max_velocity_y)
	
	var collision:KinematicCollision2D = move_and_collide(_velocity * delta)
	# 衝突処理
	_hit(collision)

func _hit(collision:KinematicCollision2D):
	if collision:
		# 着地したら消滅
		freeze()


## スパイクに何かが衝突した.
func _on_Spike_body_entered(body: CollisionObject2D) -> void:
	if body.collision_layer & (1 << Common.eColLayer.PLAYER):
		# プレイヤーと衝突.
		body.vanish()
