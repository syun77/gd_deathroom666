extends Node2D

var _timer:float

@onready var _spr = $Player

# ゴーストエフェクト開始
func start(_position:Vector2, _scale:Vector2, _frame:int, _flip_h:bool, _is_front_flip):
	if _is_front_flip:
		# 前方宙返り
		_spr = $PlayerFrontFlip
	_spr.visible = true
	
	position = _position
	_spr.scale = _scale
	_spr.frame = _frame
	_spr.flip_h = _flip_h
	_timer = 1.0

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0:
		# タイマー終了で消える
		queue_free()

	var alpha = _timer * 0.5
	modulate.a = alpha
