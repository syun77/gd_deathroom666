extends Area2D

class_name ItemSuper

onready var _spr = $Sprite
onready var _spr_add = $Sprite2 # 加算合成用スプライト.
onready var _snd = $AudioStreamPlayer

var _timer = 0.0
var _color = Common.eBlock.RED
var _velocity = Vector2.ZERO

func vanish() -> void:
	Common.play_se("flash", 1)
	var col = Common.get_block_color(_color)
	Common.start_particle_ring(position, 1.0, col)
	Common.start_particle(position, 1.0, col)
	queue_free()

func set_color(color:int) -> void:
	_color = color

## 同じ色かどうか.
func is_same_color(color:int) -> bool:
	return _color == color

func _get_anim_idx() -> int:
	match _color:
		Common.eBlock.RED:
			return 0
		Common.eBlock.GREEN:
			return 3
		_:  # Common.eBlock.BLUE
			return 1

func _ready() -> void:
	_spr.frame = _get_anim_idx()
	_spr_add.frame = 2 # 白色.
	
	var rect = Common.get_camera_rect()
	var center = rect.get_center()
	position.x = center.x + rand_range(-128.0, 128)
	position.y = rect.position.y
	
	_velocity.x = rand_range(-100, 100)
	_velocity.y = rand_range(50, 100)

func _process(delta: float) -> void:
	_timer += delta
	
	# 点滅.
	_spr_add.modulate.a = 0.3 * abs(sin(_timer * 3))
	
	position += _velocity * delta
	
	# 跳ね返り判定.
	var rect = Common.get_camera_rect()
	var left = Common.TILE_SIZE * 1.5
	var right = Common.SCREEN_W - Common.TILE_SIZE * 1.5
	var top = rect.position.y + Common.TILE_HALF
	var bottom = rect.end.y - Common.TILE_SIZE
	
	if position.x < left:
		position.x = left
		_velocity.x *= -1
	if position.x > right:
		position.x = right
		_velocity.x *= -1
	if position.y < top:
		position.y = top
		_velocity.y *= -1
	if position.y > bottom:
		position.y = bottom
		_velocity.y *= -1

func add_banana(pos:Vector2) -> void:
	var deg = rand_range(30, 150)
	Common.add_item(pos, deg, 500)

func _on_ItemSuper_body_entered(body: Node) -> void:
	var layer = body.collision_layer
	if layer & (1 << Common.eColLayer.PLAYER):
		# プレイヤーと衝突.
		match _color:
			Common.eBlock.RED:
				# 敵弾をすべて消す.
				for bullet in Common.get_layer("bullet").get_children():
					# バナナを出現させる.
					add_banana(bullet.position)
					bullet.vanish()
			Common.eBlock.GREEN:
				# 落下ブロックをすべて足場にする.
				for block in Common.get_layer("wall").get_children():
					# ブロックを足場に変化させる.
					if block is Block:
						block.freeze()
						# バナナを出現させる.
						add_banana(block.position)
			Common.eBlock.BLUE:
				Common.start_slow_block()
		
		vanish()
