extends Node2D

@onready var _bg = $ColorRect
@onready var _label = $Label

func _ready() -> void:
	_set_visible(false)

func _set_visible(b:bool) -> void:
	_bg.visible = b
	_label.visible = b

func _process(delta: float) -> void:
	_set_visible(false)
	if Common.is_slow_blocks() == false:
		return

	_set_visible(true)
	_bg.modulate.a = Common.get_slow_blocks_rate()
	_label.text = "BULLET-TIME:%3.2f"%Common.get_slow_blocks()
