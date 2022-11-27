extends KinematicBody2D

const ANIM_SPEED = 7 # アニメーション速度
const MOVE_SPEED = 30
const DECAY_MOVE_SPEED = 0.9 
const GRAVITY = 40
const JUMP_POWER = 800
const MAX_JUMP_CNT = 2 # 2段ジャンプまで可能.

onready var _spr = $Player


var _velocity = Vector2.ZERO # 速度ベクトル.
var _is_jumping = false # ジャンプ中かどうか
var _is_directon_left = false # 左向きかどうか.
var _tAnim:float = 0 # アニメーションタイマー.
var _cnt_jump = 0 # ジャンプ回数.

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
	
	# 移動処理.
	# ※第2引数に床と判定する方向ベクトルを渡す必要がある
	_velocity = move_and_slide(_velocity, Vector2.UP)
	
	if is_on_floor():
		_is_jumping = false # 床に着地している
		_velocity.y = 0 # 重力クリア.	
		_cnt_jump = 0 # ジャンプ回数をリセットする.
		for i in range(get_slide_count()):
			var col:KinematicCollision2D = get_slide_collision(i)
			var collider:CollisionObject2D = col.collider
			if collider.collision_layer & (1 << 3): # layer '4'
				# Block(落下床)に衝突したので固定化させる.
				collider.freeze()
	else:
		_is_jumping = true # ジャンプ中.
	
	# 衝突対象を取得する.
	for i in range(get_slide_count()):
		var col:KinematicCollision2D = get_slide_collision(i)
		var collider:CollisionObject2D = col.collider
		if collider.collision_layer & (1 << 2): # layer '3'
			# Spikeと衝突した.
			print("Spikeと衝突")

	if _cnt_jump < MAX_JUMP_CNT:
		if Input.is_action_just_pressed("act_jump"):
			# ジャンプ.
			_velocity.y = -JUMP_POWER
			_cnt_jump += 1

func _process(delta: float) -> void:
	_update_anim(delta)

func _update_anim(delta:float) -> void:
	_tAnim += delta
	
	# アニメーションの切り替え.
	if _velocity.x < 0:
		_is_directon_left = true # 左向き
	elif _velocity.x > 0:
		_is_directon_left = false # 右向き

	_spr.flip_h = _is_directon_left
	
	if _is_jumping:
		# ジャンプ中
		if _cnt_jump == 1:
			# 2段ジャンプできるので前方宙返りする.
			var rot_speed = 2000
			if _is_directon_left:
				rot_speed *= -1
			_spr.rotation_degrees += rot_speed * delta
		else:
			_spr.rotation_degrees = 0
		_spr.frame = 2
		return
	
	# 回転をリセットする.
	_spr.rotation_degrees = 0	
	
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
