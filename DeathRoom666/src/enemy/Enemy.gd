extends KinematicBody2D

# --------------------------------
# preload.
# --------------------------------
const Bullet = preload("res://src/bullet/Bullet.tscn")

# --------------------------------
# 定数.
# --------------------------------
const MOVE_DECAY = 0.97 # 移動量の減衰値.
const CAMERA_OFFSET_Y = -350.0

# --------------------------------
# exports.
# --------------------------------

# --------------------------------
# exports.
# --------------------------------
onready var _spr = $Enemy

# --------------------------------
# vars.
# --------------------------------
var _camera:Camera2D = null
var _velocity := Vector2()
var _timer := 0.0
var _target:Node2D = null
var _bullets:CanvasLayer = null

# --------------------------------
# public functions.
# --------------------------------
func set_camera(camera:Camera2D) -> void:
	_camera = camera
func set_target(target:Node2D) -> void:
	_target = target
func set_bullets(bullets:CanvasLayer) -> void:
	_bullets = bullets

# --------------------------------
# private functions.
# --------------------------------
func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	_velocity *= MOVE_DECAY
	
	# カメラが移動したらそれに合わせて移動する.
	var dy = (_camera.position.y + CAMERA_OFFSET_Y) - position.y
	_velocity.y = dy * 2
	
	_velocity = move_and_slide(_velocity)

func _set_velocity(deg:float, speed:float) -> void:
	var rad = deg2rad(deg)
	_velocity.x = cos(rad) * speed
	_velocity.y = -sin(rad) * speed
	
## 狙い撃ち角度を取得する.
func _get_aim() -> float:
	if _target == null:
		return 180.0
	
	var d = _target.position - position
	return rad2deg(atan2(-d.y, d.x))
	
func _get_aim2() -> float:
	if _target == null:
		return 180.0
	
	var d = _target.position - position
	return rad2deg(atan2(d.y, d.x))

func _process(delta: float) -> void:
	var prev = int(_timer * 0.5)
	_timer += delta
	var next = int(_timer * 0.5)
	if prev != next:
		var deg = 0
		if randi()%2 == 1:
			deg = 180
		_set_velocity(deg, 200)
		
		var aim = _get_aim()
		_bullet(aim-2, 300)
		_bullet(aim, 300)
		_bullet(aim+2, 300)

	# 画像の回転.
	_spr.rotation_degrees = _get_aim2()
	
## 弾を撃つ.
func _bullet(deg:float, speed:float, ofs:Vector2 = Vector2.ZERO) -> void:
	var b = Bullet.instance()
	b.position = position + ofs
	b.set_velocity(deg, speed)
	_bullets.add_child(b)
