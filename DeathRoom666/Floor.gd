extends Area2D

class_name Floor

onready var collision = $CollisionShape2D

func get_hit_rect() -> Rect2:
	var shape:RectangleShape2D = collision.shape
	var size = shape.extents
	var pos = position-size
	size *= 2
	var r = Rect2(pos, size)
	return r

func _ready() -> void:
	pass


func _on_Floor_body_entered(body: Node) -> void:
	# コリジョンレイヤー.
	var layer = body.collision_layer

	if layer & (1 << Common.eColLayer.PLAYER):
		# プレイヤーの場合は衝突対象を登録する.
		body.set_on_floor(self)
