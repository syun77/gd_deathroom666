extends KinematicBody2D

const MOVE_SPEED = 30
const DECAY_MOVE_SPEED = 0.9 
const GRAVITY = 40
const JUMP_POWER = 800

onready var _spr = $Player


var _velocity = Vector2.ZERO # 速度ベクトル.
var _is_jumping = false # ジャンプ中かどうか
var _is_directon_left = false # 左向きかどうか.
var _tAnim:float = 0 # アニメーションタイマー.

func _physics_process(delta: float) -> void:
	# 重力を加算
	_velocity.y += GRAVITY
	
	# 移動量を減衰.
	_velocity.x *= DECAY_MOVE_SPEED
	
	# 左右移動.
	if Input.is_action_pressed("ui_left"):
		_velocity.x -= MOVE_SPEED # 左方向に移動
	elif Input.is_action_pressed("ui_right"):
		_velocity.x += MOVE_SPEED # 右方向に移動.
	
	# ジャンプ.
	if _is_jumping == false:
		# ジャンプ中でなければジャンプできる.
		if Input.is_action_just_pressed("act_jump"):
			# ジャンプする.
			_velocity.y = -JUMP_POWER
	
	# 移動処理.
	# ※第2引数に床と判定する方向ベクトルを渡す必要がある
	_velocity = move_and_slide(_velocity, Vector2.UP)
	
	if is_on_floor():
		_is_jumping = false # 床に着地している
		
		# 衝突対象を取得する.
		for i in range(get_slide_count()):
			var col = get_slide_collision(i)
			# とりあえず名前で判断
			if "Block" in col.collider.name:
				col.collider.freeze()
	else:
		_is_jumping = true # ジャンプ中.


func _process(delta: float) -> void:
	_tAnim += delta
	
	# アニメーションの切り替え.
	if _velocity.x < 0:
		_is_directon_left = true # 左向き
	elif _velocity.x > 0:
		_is_directon_left = false # 右向き

	_spr.flip_h = _is_directon_left
	
	var tbl = [0, 1];
	var t = _tAnim
	if abs(_velocity.x) > 50:
		# 速度が50以上なら走り中.
		tbl = [2, 3]
		t *= 8 # アニメーション速度を上げる

	t = int(t) % 2
	_spr.frame = tbl[t]
	
	if _is_jumping:
		# ジャンプ中は2番目固定.
		_spr.frame = 2
