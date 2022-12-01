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

#-----------------------------------
# public functions.
#-----------------------------------
func setup(layers) -> void:
	_layers = layers
	
func get_layer(name:String) -> CanvasLayer:
	return _layers[name]

func add_particle() -> Particle:
	var parent = get_layer("effect")
	var p = ParticleObj.instance()
	parent.add_child(p)
	return p

func start_particle(pos:Vector2, time:float, color:Color) -> void:
	var deg = rand_range(0, 360)
	for i in range(8):
		var p = add_particle()
		p.position = pos
		var speed = rand_range(100, 1000)
		p.start(time, deg, speed, 0, 10, color)
		deg += rand_range(30, 50)
