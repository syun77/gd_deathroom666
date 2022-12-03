extends KinematicBody2D

# ---------------------------------------
# preload.
# ---------------------------------------
#const Wall = preload("res://Wall.tscn")
const Wall = preload("res://Floor.tscn")

# ---------------------------------------
# 定数.
# ---------------------------------------
const GRAVITY = 40
const DEFAULT_MAX_VELOCITY = 100

# ---------------------------------------
# onready.
# ---------------------------------------
onready var _spike = $Spike

# ---------------------------------------
# vars.
# ---------------------------------------
var _parent:CanvasLayer = null
var _velocity = Vector2()
var _freezed = false
var _max_velocity_y = DEFAULT_MAX_VELOCITY

# ---------------------------------------
# public functions.
# ---------------------------------------
## Y方向の最高速度を設定する.
func set_max_velocity_y(dy:float) -> void:
	_max_velocity_y = dy

## 動きを止める.
func freeze() -> bool:
	if _freezed:
		return false # フリーズ済み.
	
	_freezed = true
	# 固定ブロックにする
	queue_free()
	var wall = Wall.instance()
	position.y -= 48.0 # 1タイルぶんずれる.
	wall.position = position
	_parent.add_child(wall)
	
	# リングエフェクト出現.
	Common.start_particle_ring(position, 1.0, Color.white)
	
	return true

## 親ノードを設定する.
func set_parent(layer:CanvasLayer) -> void:
	_parent = layer

# ---------------------------------------
# private functions.
# ---------------------------------------
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

# ---------------------------------------
# signals.
# ---------------------------------------
## スパイクに何かが衝突した.
func _on_Spike_body_entered(body: CollisionObject2D) -> void:
	if body.collision_layer & (1 << Common.eColLayer.PLAYER):
		# プレイヤーと衝突.
		body.vanish()
