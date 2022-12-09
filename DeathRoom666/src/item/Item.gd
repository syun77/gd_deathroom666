extends Area2D

class_name Item

# --------------------------
# 定数.
# --------------------------
const GRAVITY = 10.0
const AUTO_COLLECT_DIST = 120.0 # 自動回収が有効となる距離.
const MAX_SPEED := 100.0
# --------------------------
# onready.
# --------------------------
onready var _spr = $Sprite

# --------------------------
# vars.
# --------------------------
var _velocity = Vector2()
var _is_auto_collect = false # 自動回収フラグ

# --------------------------
# public functions.
# --------------------------
## 速度を設定する.
func set_velocity(deg:float, speed:float) -> void:
	var rad = deg2rad(deg)
	_velocity.x = cos(rad) * speed
	_velocity.y = -sin(rad) * speed

## 消滅
func vanish() -> void:
	Common.start_particle_ring(position, 1.0, Color.yellow)
	Common.add_score(100)
	Common.add_ascii(position, "100")
	Common.play_se("coin")
	queue_free()
# --------------------------
# private functions.
# --------------------------
func _ready() -> void:
	_spr.rotation_degrees = rand_range(0, 360)

## 速度を固定化したいので、_physics_process() で処理する.
func _physics_process(delta: float) -> void:
	# スプライトを回転する.
	_spr.rotation_degrees += 100 * delta
	
	# プレイヤーに近い場合は近づく.
	var dist = Common.get_player_distance(position)
	if dist < 128.0:
		_is_auto_collect = true
	
	if _is_auto_collect:
		var target = Common.get_player_position()
		_velocity += (target - position) * 0.5
	
	# 移動する
	_velocity.y += GRAVITY
	_velocity *= 0.97
	if _velocity.y > MAX_SPEED:
		_velocity.y = MAX_SPEED
	position += _velocity * delta	

	# 左右の壁にめり込まないようにする.
	var left = Common.TILE_SIZE * 1.5
	var right = Common.SCREEN_W - Common.TILE_SIZE * 1.5
	if position.x < left:
		position.x = left
	if position.x > right:
		position.x = right


func _on_Item_body_entered(body: Node) -> void:
	# アイテム獲得.
	vanish()
