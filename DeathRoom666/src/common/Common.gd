extends Node
#-----------------------------------
# preload.
#-----------------------------------
const ItemObj     = preload("res://src/item/Item.tscn")
const ParticleObj = preload("res://src/effects/Particle.tscn")
const AsciiObj    = preload("res://src/effects/ParticleAscii.tscn")

#-----------------------------------
# 定数.
#-----------------------------------
# タイル関連.
const TILE_SIZE := 48.0
const TILE_HALF := TILE_SIZE / 2.0 # タイルの半分のサイズ.

# 画面の幅.
const SCREEN_W:int = 480

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

#-----------------------------------
# vars.
#-----------------------------------
var _hiscore = 0
var _score = 0
var _layers = []
var _player:Player = null
var _prev_target_pos = Vector2.ZERO # 前回のターゲットの座標.

var _snd:AudioStreamPlayer
var _snd_tbl = {
	"damage": "res://assets/sound/damage.wav",
	"explosion" : "res://assets/sound/explosion.wav",
	"coin": "res://assets/sound/coin.wav",
}

#-----------------------------------
# public functions.
#-----------------------------------
func get_score() -> int:
	return _score
	
func add_score(v:int) -> void:
	_score += v

func init() -> void:
	_hiscore = 0
	_score = 0
	
func setup(root, layers, player:Player) -> void:
	_score = 0
	
	_layers = layers
	_player = player
	_snd = AudioStreamPlayer.new()
	_snd.volume_db = -4
	root.add_child(_snd)
	
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
	var aim = rad2deg(atan2(-d.y, d.x))
	
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
	var p = ParticleObj.instance()
	parent.add_child(p)
	return p

func start_particle(pos:Vector2, time:float, color:Color, sc:float=1.0) -> void:
	var deg = rand_range(0, 360)
	for i in range(8):
		var p = add_particle()
		p.position = pos
		var speed = rand_range(100, 1000)
		var t = time + rand_range(-0.2, 0.2)
		p.start(t, deg, speed, 0, 10, color, sc)
		deg += rand_range(30, 50)

func start_particle_ring(pos:Vector2, time:float, color:Color, sc:float=2.0) -> void:
	var p = add_particle()
	p.position = pos
	p.start_ring(time, color, sc)

func start_particle_enemy(pos:Vector2, time:float, color:Color) -> void:
	start_particle(pos, time, color, 2.0)
	for i in range(3):
		start_particle_ring(pos, time + (i * 0.2), color, pow(2.0, (1 + i)))

func add_item(pos:Vector2, deg:float, speed:float) -> Item:
	var item = ItemObj.instance()
	item.position = pos
	item.set_velocity(deg, speed)
	get_layer("item").add_child(item)
	return item

func add_ascii(pos:Vector2, s:String) -> void:
	var p = AsciiObj.instance()
	get_layer("effect").add_child(p)
	p.init(pos, s)

func play_se(name:String) -> void:
	if not name in _snd_tbl:
		push_error("存在しないサウンド %s"%name)
		return
	
	_snd.stream = load(_snd_tbl[name])
	_snd.play()

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
