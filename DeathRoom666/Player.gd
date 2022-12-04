extends KinematicBody2D

# ------------------------------------
# 依存シーン.
# ------------------------------------
const GHOST_EFFECT = preload("res://src/effects/GhostEffect.tscn")
const SHOT_OBJ = preload("res://src/shot/Shot.tscn")

# ------------------------------------
# 定数
# ------------------------------------
const ANIM_SPEED = 7 # アニメーション速度
const MOVE_SPEED = 30
const DECAY_MOVE_SPEED := 0.9 
const GRAVITY = 40
const JUMP_POWER = 800
const MAX_JUMP_CNT = 2 # 2段ジャンプまで可能.
const JUMP_SCALE_TIME := 0.2

# スプライトフレーム番号.
enum eSpr {
	STANDBY1 = 0, # 待機1
	STANDBY2, # 待機2
	RUN1, # 走り1
	RUN2, # 走り2
	BREAK, # ブレーキ
	DAMAGE1, # ダメージ1
	DAMAGE2, # ダメージ2
	CRY, # 悲しい 
};

# 状態
enum eJumpState {
	IDLE,
	RUN, # 走る
	JUMP # ジャンプ
}

# ジャンプによるスケール状態
enum eJumpScale {
	NONE,
	JUMPING, #ジャンプ開始
	LANDING, # 着地開始
}

# ------------------------------------
# export.
# ------------------------------------
# エフェクトレイヤー.
export(NodePath) var _effect_layer
var _effects:CanvasLayer = null

# ------------------------------------
# onready.
# ------------------------------------
onready var _spr_normal = $Player
onready var _spr_front_flip = $PlayerFrontFlip
onready var _spr = $Player
onready var _barrier = $Barrier
onready var _audio_jump = $AudioJump
onready var _auiod_beam = $AudioBeam

# ------------------------------------
# メンバ変数.
# ------------------------------------
var _velocity = Vector2.ZERO # 速度ベクトル.
var _is_jumping = false # ジャンプ中かどうか
var _is_directon_left = false # 左向きかどうか.
var _is_input_run = false # 走りの入力をしている.
var _tAnim:float = 0 # アニメーションタイマー.
var _cnt_jump = 0 # ジャンプ回数.
var _ghost_timer := 0.0 # 残像エフェクトタイマー.
var _request_dead = false # 死亡リクエスト.

# ジャンプ関連.
var _jump_state = eJumpState.IDLE
var _jump_scale = eJumpScale.NONE
var _jump_scale_timer = 0

var _cnt_damage_anim = 0

# ------------------------------------
# public function.
# ------------------------------------

## 踏みつけ.
func stomp() -> void:
	_velocity.y = -1000

## 消滅開始.
func vanish() -> void:
	_request_dead = true
	# 更新を止める.
	set_process(false)
	set_physics_process(false)
	
	Common.play_se("damage")

## 死亡リクエストがあるかどうか.
func is_request_dead() -> bool:
	return _request_dead

# ダメージアニメ更新.
func update_damage() -> void:
	_cnt_damage_anim += 1
	if _cnt_damage_anim%4 < 2:
		_spr.frame = eSpr.DAMAGE1
	else:
		_spr.frame = eSpr.DAMAGE2

# ------------------------------------
# private function.
# ------------------------------------
## ready.
func _ready() -> void:
	# バリアを無効にしておく.
	_enable_barrier(false)

## バリアの有効フラグを設定.
func _enable_barrier(b:bool) -> void:
	_barrier.visible = b # 表示フラグを設定.
	_barrier.monitoring = b # 衝突を自身が検知するかどうか.
	_barrier.monitorable = b # 他者が衝突判定をするかどうか.
	
## 物理更新.
func _physics_process(delta: float) -> void:
	if _request_dead:
		# 死亡リクエストが届いた.
		Common.start_particle(position, 1.0, Color.magenta)
		Common.start_particle_ring(position, 1.0, Color.magenta, 4.0)
		Common.play_se("explosion")
		queue_free()
		
	# 重力を加算
	_velocity.y += GRAVITY
	
	# 移動量を減衰.
	_velocity.x *= DECAY_MOVE_SPEED
	
	# 左右移動.
	_is_input_run = false
	if Input.is_action_pressed("ui_left"):
		_velocity.x -= MOVE_SPEED # 左方向に移動
		_is_input_run = true
	elif Input.is_action_pressed("ui_right"):
		_velocity.x += MOVE_SPEED # 右方向に移動.
		_is_input_run = true
	
	# 移動処理.
	# ※第2引数に床と判定する方向ベクトルを渡す必要がある
	_velocity = move_and_slide(_velocity, Vector2.UP)
	
	if is_on_floor():
		# 床に着地しているときの処理.
		_on_floor()
	else:
		_is_jumping = true # ジャンプ中.

	# 衝突チェックする.	
	_check_collision()

	# ジャンプ判定する.
	if _cnt_jump < MAX_JUMP_CNT:
		if Input.is_action_just_pressed("act_jump"):
			# ジャンプできる.
			_audio_jump.play()
			_jump_state = eJumpState.JUMP
			_velocity.y = -JUMP_POWER
			_cnt_jump += 1
			if _is_front_flip():
				_jump_scale = eJumpScale.JUMPING
				_jump_scale_timer = JUMP_SCALE_TIME
	
	if _is_jumping == false:
		# ジャンプしていなければバリア有効.
		_enable_barrier(true)
	else:
		_enable_barrier(false)
		
## 着地したときの処理.
func _on_floor() -> void:
	_is_jumping = false # 床に着地している
	if _jump_state == eJumpState.JUMP:
		# 着地した.
		_jump_scale = eJumpScale.LANDING
		_jump_scale_timer = JUMP_SCALE_TIME
	_jump_state = eJumpState.IDLE
				
	_velocity.y = 0 # 重力クリア.	
	_cnt_jump = 0 # ジャンプ回数をリセットする.
	for i in range(get_slide_count()):
		var col:KinematicCollision2D = get_slide_collision(i)
		var collider:CollisionObject2D = col.collider
		if collider.collision_layer & (1 << Common.eColLayer.BLOCK):
			# Block(落下床)に衝突したので固定化させる.
			if collider.freeze():
				# 弾を撃つ
				_shoot(3)

## 衝突チェックする.
func _check_collision():
	
	# 衝突対象を取得する.
	for i in range(get_slide_count()):
		var col:KinematicCollision2D = get_slide_collision(i)
		var collider:CollisionObject2D = col.collider
		if collider.collision_layer & (1 << Common.eColLayer.SPIKE):
			# Spikeと衝突した.
			vanish()

## 更新.
func _process(delta: float) -> void:	
	_update_anim(delta)
	
	# 残像エフェクト更新.
	_update_ghost_effect(delta)
	
	# ジャンプ・着地演出
	_update_jump_scale_anim(delta)


## 更新 > アニメ.
func _update_anim(delta:float) -> void:
	_tAnim += delta
	
	# アニメーションの切り替え.
	if _velocity.x < 0:
		_is_directon_left = true # 左向き
	elif _velocity.x > 0:
		_is_directon_left = false # 右向き

	# 反転フラグを設定する.
	_spr.flip_h = _is_directon_left
	
	if _is_jumping:
		# ジャンプ中
		_update_jump(delta)
		return
	
	# 着地している.
	# 回転をリセットする.
	_spr.rotation_degrees = 0	
	
	var tbl = [eSpr.STANDBY1, eSpr.STANDBY2];
	var t = _tAnim
	if abs(_velocity.x) > 30.0:
		# 速度が50以上なら走り中.
		tbl = [eSpr.RUN1, eSpr.RUN2]
		t *= 8 # アニメーション速度を上げる
	elif abs(_velocity.x) > 10.0 and _is_input_run == false:
		# ブレーキアニメーション.
		tbl = [eSpr.BREAK, eSpr.BREAK]

	t = int(t) % 2
	_spr.frame = tbl[t]

## 更新 > 残像エフェクト.
func _update_ghost_effect(delta:float) -> void:
	var time_scale = 10.0 # 0.1秒に1つ出現させる.
	var prev = int(_ghost_timer * time_scale)
	_ghost_timer += delta
	var next = int(_ghost_timer * time_scale)

	if prev != next:
		if _effects == null:
			_effects = get_node(_effect_layer)
		if _effects != null:
			var eft = GHOST_EFFECT.instance()
			_effects.add_child(eft)
			var is_front_flip = _is_front_flip()
			eft.start(position, _spr.scale, _spr.frame, _spr.flip_h, is_front_flip)
	

## 更新 > ジャンプアニメーション.
func _update_jump(delta:float) -> void:
	if _is_front_flip(): # 1段目ジャンプ中.
		# 2段ジャンプできるので前方宙返りする.
		var rot_speed = 2000 # 回転速度.
		if _is_directon_left:
			rot_speed *= -1 # 逆回転.
		_spr.rotation_degrees += rot_speed * delta
	else:
		_spr.rotation_degrees = 0 # 回転リセット.
	_spr.frame = eSpr.RUN1

## 更新 > ジャンプ・着地によるスケールアニメーションの更新
func _update_jump_scale_anim(delta:float) -> void:
	# 描画対象となるスプライトの切り替え.
	_spr_normal.visible = false
	_spr_front_flip.visible = false
	if _is_front_flip(): # 回転させる.
		_spr = _spr_front_flip
	else:
		_spr = _spr_normal
	_spr.visible = true

	# スケールタイマー更新.
	_jump_scale_timer = max(_jump_scale_timer - delta, 0.0)	
	if _jump_scale_timer == 0.0:
		# ジャンプスケール終了.
		_jump_scale = eJumpScale.NONE
	
	match _jump_scale:
		eJumpScale.JUMPING:
			# 縦に伸ばす
			var d = 0.4 * _jump_scale_timer / JUMP_SCALE_TIME
			_spr.scale.x = 1 - d
			_spr.scale.y = 1 + d
		eJumpScale.LANDING:
			# 縦に潰す
			var d = 0.4 * _jump_scale_timer / JUMP_SCALE_TIME
			_spr.scale.x = 1 + d
			_spr.scale.y = 1 - d
		_:
			# もとに戻す
			_spr.scale.x = 1
			_spr.scale.y = 1


## 前方宙返り中かどうか
func _is_front_flip() -> bool:
	if _cnt_jump != 1:
		return false
	
	return true

func _shoot(cnt:int) -> void:
	var enemies = Common.get_layer("enemy")
	if enemies.get_child_count() == 0:
		return # 敵がいない場合は発生しない.
	
	var v := Vector2()
	# ショットを発生させる.
	for i in range(cnt):
		var spd = rand_range(300, 800)
		var rad = deg2rad(270 + rand_range(-50, 50))
		v.x = cos(rad) * spd
		v.y = -sin(rad) * spd
		var parent = Common.get_layer("shot")
		var s = SHOT_OBJ.instance()
		s.position = position
		s.set_velocity(v)
		parent.add_child(s)
	_auiod_beam.play()

## バリアに何かが衝突.
func _on_Barrier_area_entered(area: CollisionObject2D) -> void:
	var layer = area.collision_layer
	if layer & (1 << Common.eColLayer.BULLET):
		# 敵弾であれば消す.
		area.vanish()
