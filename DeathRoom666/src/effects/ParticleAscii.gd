extends Node2D

const TIMER_VANISH = 1.0 # 1.0秒で消える.

@onready var _label = $Label

var _velocity = Vector2(0, -50)
var _timer = 0.0

## 初期化.
func init(pos:Vector2, s:String) -> void:
	position = pos
	_label.text = s	

## 更新.
func _process(delta: float) -> void:
	var rate = _timer / TIMER_VANISH
	modulate.a = 1.0 - rate # 透過で消す.
	
	position += _velocity * delta
	
	_timer += delta
	if _timer >= TIMER_VANISH:
		queue_free()
