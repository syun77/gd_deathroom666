extends Sprite

class_name Particle

var _velocity = Vector2.ZERO
var _accel = Vector2.ZERO
var _timer := 0.0
var _timer_max := 0

func start(t:float, deg:float, speed:float, ax:float, ay:float, color:Color) -> void:
	var rad = deg2rad(deg)
	_velocity.x = cos(rad) * speed
	_velocity.y = -sin(rad) * speed
	_accel.x = ax
	_accel.y = ay
	_timer = t
	_timer_max = t

func _process(delta: float) -> void:
	_velocity += _accel
	_velocity *= 0.93 # 減衰
	position += _velocity * delta
	
	_timer -= delta
	if _timer <= 0:
		queue_free()
		return
	
	var rate = _timer / _timer_max
	var sc = rate
	scale.x = sc
	scale.y = sc
	
