extends TileMapLayer

func draw_move_range(cells: Array) -> void:
	for cell in cells:
		set_cell(cell, 0, Vector2i(0,1))
	
func draw_attack_range(cells: Array)->void:
	for cell in cells:
		set_cell(cell, 0, Vector2i(0,0))
