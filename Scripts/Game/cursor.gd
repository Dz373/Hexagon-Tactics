class_name Cursor extends Node2D

@onready var camera = $Camera2D
@onready var gameManager = $".."

var cell: Vector2i:
	set(val):
		if val == Vector2i(-999, -999):
			val = Vector2i(0,0)
		cell = val
		position = HexNavi.cell_to_global(val)

func _process(_delta: float) -> void:
	if gameManager.unitMenu.visible:
		return
	
	cell = HexNavi.global_to_cell(get_global_mouse_position())
	
	'if Input.is_action_just_pressed("zoom_in"):
		if camera.zoom.x >= 4:
			return
		camera.zoom += Vector2.ONE*.5
	
	elif Input.is_action_just_pressed("zoom_out"):
		if camera.zoom.x <= 1:
			return
		camera.zoom -= Vector2.ONE*.5'
		
