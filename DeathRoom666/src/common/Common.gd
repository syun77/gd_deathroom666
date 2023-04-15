extends Node
#-----------------------------------
# preload.
#-----------------------------------
const ItemObj      = preload("res://src/item/Item.tscn")
const ItemSuperObj = preload("res://src/item/ItemSuper.tscn")
const ParticleObj  = preload("res://src/effects/Particle.tscn")
const AsciiObj     = preload("res://src/effects/ParticleAscii.tscn")

#-----------------------------------
# 定数.
#-----------------------------------
# タイル関連.
const TILE_SIZE := 48.0
const TILE_HALF := TILE_SIZE / 2.0 # タイルの半分のサイズ.

# 画面の幅.
const SCREEN_W:int = 480

const TIMER_SLOW = 7.0

const MAX_SOUND = 8

# コリジョンレイヤー.
enum eColLayer {
	PLAYER = 0,
	WALL = 1,
	SPIKE = 2,
	BLOCK = 3,
	ENEMY = 4,
	BULLET = 5,
	SHOT = 6,
}

# 移動床の色.
enum eBlock {
	RED,
	YELLOW,
	BLUE,
	GREEN,
}

#-----------------------------------
# vars.
#-----------------------------------
var _hiscore = 0
var _score = 0
var _layers = []
var _camera:Camera2D = null
var _player:Player = null
var _prev_target_pos = Vector2.ZERO # 前回のターゲットの座標.
var _timer_slow = 0.0

var _snds = []
var _snd_tbl = {
	"damage": "res://assets/sound/damage.wav",
	"explosion" : "res://assets/sound/explosion.wav",
	"coin": "res://assets/sound/coin.wav",
	"flash": "res://assets/sound/flash.wav",
}

#-----------------------------------
# public functions.
#-----------------------------------
func get_score() -> int:
	return _score
	
func add_score(v:int) -> void:
	_score += v
	
	if _score > _hiscore:
		# ハイスコア更新.
		_hiscore = _score
	
func get_hiscore() -> int:
	return _hiscore

func init() -> void:
	_hiscore = 0
	_score = 0

## 各種変数の初期化.
func init_vars() -> void:
	_score = 0
	_timer_slow = 0.0
	_snds.clear()
	
func setup(root, layers, player:Player, camera:Camera2D) -> void:
	init_vars()
	
	_layers = layers
	_player = player
	_camera = camera
	for i in range(MAX_SOUND):
		var snd = AudioStreamPlayer.new()
		snd.volume_db = -4
		root.add_child(snd)
		_snds.append(snd)

func is_slow_blocks() -> bool:
	return _timer_slow > 0.0

func update_slow_blocks(delta:float) -> void:
	if _timer_slow > 0.0:
		_timer_slow -= delta
		
func get_slow_blocks_rate() -> float:
	if is_slow_blocks() == false:
		return 0.0
	
	return _timer_slow / TIMER_SLOW
	
func get_bullet_time_rate() -> float:
	if is_slow_blocks():
		return 0.5
	return 1.0

func get_slow_blocks() -> float:
	return _timer_slow
	
func get_player() -> Player:
	if is_instance_valid(_player) == false:
		return null
	return _player

func get_aim(pos:Vector2) -> float:
	var player = get_player()
	var target = _prev_target_pos
	if player != null:
		target = player.position
	
	var d = target - pos
	var aim = rad_to_deg(atan2(-d.y, d.x))
	
	# ターゲットの座標を保存しておく.
	_prev_target_pos = target
	
	return aim

func get_player_position() -> Vector2:
	var player = get_player()
	if player == null:
		return _prev_target_pos
	return player.position
	
func get_player_distance(pos:Vector2) -> float:
	var player = get_player()
	if player == null:
		return 9999999.0
	var d = player.position - pos
	return d.length()

func get_layer(name:String) -> CanvasLayer:
	return _layers[name]

func add_particle() -> Particle:
	var parent = get_layer("effect")
	var p = ParticleObj.instantiate()
	parent.add_child(p)
	return p

func start_particle(pos:Vector2, time:float, color:Color, sc:float=1.0) -> void:
	var deg = randf_range(0, 360)
	for i in range(8):
		var p = add_particle()
		p.position = pos
		var speed = randf_range(100, 1000)
		var t = time + randf_range(-0.2, 0.2)
		p.start(t, deg, speed, 0, 10, color, sc)
		deg += randf_range(30, 50)

func start_particle_ring(pos:Vector2, time:float, color:Color, sc:float=2.0) -> void:
	var p = add_particle()
	p.position = pos
	p.start_ring(time, color, sc)

func start_particle_enemy(pos:Vector2, time:float, color:Color) -> void:
	start_particle(pos, time, color, 2.0)
	for i in range(3):
		start_particle_ring(pos, time + (i * 0.2), color, pow(2.0, (1 + i)))

func add_item(pos:Vector2, deg:float, speed:float) -> Item:
	var item = ItemObj.instantiate()
	item.position = pos
	item.set_velocity(deg, speed)
	get_layer("item").add_child(item)
	return item
	
func add_item2() -> void:
	var pos = Vector2()
	pos.x = SCREEN_W/2 + randf_range(-128, 128)
	pos.y = _camera.position.y - 420
	add_item(pos, 0, 0)

func add_super_item(color:int) -> void:
	var layer = get_layer("item")
	for item in layer.get_children():
		if item is ItemSuper:
			if item.is_same_color(color):
				return # 同じ色のアイテムが存在する場合は出現させない
		
	var item = ItemSuperObj.instantiate()
	item.set_color(color)
	layer.add_child(item)

func add_ascii(pos:Vector2, s:String) -> void:
	var p = AsciiObj.instantiate()
	get_layer("effect").add_child(p)
	p.init(pos, s)

func play_se(name:String, id:int=0) -> void:
	if id < 0 or MAX_SOUND <= id:
		push_error("不正なサウンドID %d"%id)
		return
	
	if not name in _snd_tbl:
		push_error("存在しないサウンド %s"%name)
		return
	
	var snd = _snds[id]
	snd.stream = load(_snd_tbl[name])
	snd.play()

## 角度差を求める.
func diff_angle(now:float, next:float) -> float:
	# 角度差を求める.
	var d = next - now
	# 0.0〜360.0にする.
	d -= floor(d / 360.0) * 360.0
	# -180.0〜180.0の範囲にする.
	if d > 180.0:
		d -= 360.0
	return d

func get_camera_rect() -> Rect2:
	var rect = _camera.get_viewport_rect()
	rect.position.y -= rect.get_center().y
	rect.position.y += _camera.position.y

	return rect

func get_block_color(block_color:int) -> Color:
	match block_color:
		eBlock.RED:
			return Color.DEEP_PINK
		eBlock.YELLOW:
			return Color.YELLOW
		eBlock.GREEN:
			return Color.CHARTREUSE
		_: # Common.eBlock.BLUE:
			return Color.DODGER_BLUE

func start_slow_block() -> void:
	_timer_slow = TIMER_SLOW
