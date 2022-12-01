extends Area2D
# ------------------------------------
# preload.
# ------------------------------------

# ------------------------------------
# 定数.
# ------------------------------------

# ------------------------------------
# onready.
# ------------------------------------

# ------------------------------------
# vars.
# ------------------------------------
# 移動方向.
var _deg := 0.0
# 速度.
var _speed := 0.0

# 経過時間
var _timer := 0.0
# ------------------------------------
# public functions.
# ------------------------------------
## 速度を設定.
func set_velocity(v:Vector2) -> void:
	_deg = rad2deg(atan2(-v.y, v.x))
	_speed = v.length()

## 速度をベクトルとして取得する.	
func get_velocity() -> Vector2:
	var v = Vector2()
	var rad = deg2rad(_deg)
	v.x = cos(rad) * _speed
	v.y = -sin(rad) * _speed
	return v

## 消滅する
func vanish() -> void:
	queue_free()

# ------------------------------------
# private functions.
# ------------------------------------
func _ready() -> void:
	pass

## 一番近いターゲットを探す.
func _search_target():
	var target_layer = Common.get_layer("enemy")
	var distance:float = 999999
	var target:Node2D = null
	for obj in target_layer.get_children():
		var d = (obj.position - position).length()
		if d < distance:
			# より近いターゲット.
			target = obj
			distance = d
	
	return target

## 更新.
func _process(delta: float) -> void:
	_timer += delta
	
	_speed += 1000 * delta # 加速する.
	if _speed > 5000:
		_speed = 5000 # 最高速度制限.
	
	var target = _search_target()
	if target != null:
		# 速度を更新.
		var d = target.position - position
		# 狙い撃ち角度を計算する.
		var aim = rad2deg(atan2(-d.y, d.x))
		var diff = _diff_angle(_deg, aim)
		# 旋回する.
		_deg += diff * delta * 3 + (diff * _timer * (delta+0.5))
	
	var v = get_velocity()
	
	position += v * delta
	
	# ****************************
	# 画面外判定はMain.gd でやります.
	# ****************************

## 角度差を求める.
func _diff_angle(now:float, next:float) -> float:
	# 角度差を求める.
	var d = next - now
	# 0.0〜360.0にする.
	d -= floor(d / 360.0) * 360.0
	# -180.0〜180.0の範囲にする.
	if d > 180.0:
		d -= 360.0
	return d

## 何かと衝突した.
func _on_Shot_area_entered(area: Area2D) -> void:
	var layer = area.collision_layer
	if layer & (1 << Common.eColLayer.ENEMY):
		# 敵と衝突したら消える.
		vanish()
