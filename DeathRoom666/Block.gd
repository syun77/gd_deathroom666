extends KinematicBody2D

class_name Block
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
onready var _spr = $Wall

# ---------------------------------------
# vars.
# ---------------------------------------
var _parent:CanvasLayer = null
var _timer = 0.0
var _velocity = Vector2()
var _freezed = false
var _max_velocity_y = DEFAULT_MAX_VELOCITY
var _color = Common.eBlock.RED

# ---------------------------------------
# public functions.
# ---------------------------------------
## Y方向の最高速度を設定する.
func set_max_velocity_y(dy:float) -> void:
	_max_velocity_y = dy

## 動きを止める.
## @param is_player プレイヤーが踏みつけたかどうか.
func freeze(is_player:bool=false) -> bool:
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
	
	if is_player:
		match _color:
			Common.eBlock.YELLOW:
				# バナナを追加
				Common.add_item2()
	
	return true

## 親ノードを設定する.
func set_parent(layer:CanvasLayer) -> void:
	_parent = layer

# ---------------------------------------
# private functions.
# ---------------------------------------
func _ready() -> void:
	var tbl = []
	tbl.append(Common.eBlock.RED)
	tbl.append(Common.eBlock.GREEN)
	tbl.append(Common.eBlock.BLUE)
	for i in range(3):
		tbl.append(Common.eBlock.YELLOW)
	
	tbl.shuffle()
	_color = tbl[0]

func _physics_process(delta: float) -> void:	
	_timer += delta
	
	# 重力を加算
	_velocity.y += GRAVITY
	_velocity.y = min(_velocity.y, _max_velocity_y)
	
	var collision:KinematicCollision2D = move_and_collide(_velocity * delta)
	# 衝突処理
	_hit(collision)
	
	# 色の更新.
	var color = _get_color()
	var rate = 0.2 * 0.8 * abs(sin(_timer * 4))
	_spr.modulate = color.linear_interpolate(Color.white, rate)
	
func _hit(collision:KinematicCollision2D):
	if collision:
		# 着地したら消滅
		freeze()

func _get_color() -> Color:
	match _color:
		Common.eBlock.RED:
			return Color.deeppink
		Common.eBlock.YELLOW:
			return Color.yellow
		Common.eBlock.GREEN:
			return Color.chartreuse
		_: # Common.eBlock.BLUE:
			return Color.dodgerblue

# ---------------------------------------
# signals.
# ---------------------------------------
## スパイクに何かが衝突した.
func _on_Spike_body_entered(body: CollisionObject2D) -> void:
	if body.collision_layer & (1 << Common.eColLayer.PLAYER):
		# プレイヤーと衝突.
		body.vanish()
