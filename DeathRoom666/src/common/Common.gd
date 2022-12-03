extends Node
#-----------------------------------
# preload.
#-----------------------------------
const ParticleObj = preload("res://src/effects/Particle.tscn")

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
var _layers = []

var _snd:AudioStreamPlayer
var _snd_tbl = {
	"damage": "res://assets/sound/damage.wav",
	"explosion" : "res://assets/sound/explosion.wav",
}

#-----------------------------------
# public functions.
#-----------------------------------
func setup(root, layers) -> void:
	_layers = layers
	_snd = AudioStreamPlayer.new()
	_snd.volume_db = -4
	root.add_child(_snd)
	
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

func play_se(name:String) -> void:
	if not name in _snd_tbl:
		push_error("存在しないサウンド %s"%name)
		return
	
	_snd.stream = load(_snd_tbl[name])
	_snd.play()
