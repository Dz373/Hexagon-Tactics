extends Node2D

@onready var ground_tiles = $Background
@onready var object_tiles = $Objects
@onready var gameManager = $".."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	HexNavi.set_current_map(ground_tiles, object_tiles, gameManager)
