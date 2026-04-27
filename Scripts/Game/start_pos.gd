extends Node2D

var cell

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cell = HexNavi.global_to_cell(position)
