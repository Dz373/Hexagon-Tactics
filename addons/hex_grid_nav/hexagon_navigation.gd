extends Node

#Method documentation: https://docs.google.com/document/d/1HwLlRmC2tDGbadkOEero5asVq6XmzpupeJX_pUEwqGg/edit?usp=sharing

var current_map : TileMapLayer
var object_map:TileMapLayer
var gameManager:GameManager
var astar = AStar2D.new()

## Initial function that binds a [TileMapLayer] to the navigation class
func set_current_map(map : TileMapLayer, obj:TileMapLayer, manager:GameManager):
	gameManager = manager
	current_map = map
	object_map = obj
	if current_map != null:
		astar.clear()
		add_all_point()
	
	set_weight_of_layer("weight")
	#print("there are " + str(astar.get_point_count()) + " points in this map")

## Adds and connects all cells in the [TileMapLayer]
func add_all_point(): 
	var all_used_cells = current_map.get_used_cells()
	for cell in all_used_cells:
		var next_id := astar.get_available_point_id()
		astar.add_point(next_id, cell)
	for point_id in astar.get_point_ids():
		var pos = astar.get_point_position(point_id)
		var all_possible_neighbors = current_map.get_surrounding_cells(pos)
		var valid_neighbor = []
		for neighbor in all_possible_neighbors:
			if current_map.get_cell_source_id(neighbor) != -1: #if the cell is not empty
				valid_neighbor.append(neighbor)
		for neighbor in valid_neighbor:
			var neighbor_id = astar.get_closest_point(neighbor)
			astar.connect_points(point_id, neighbor_id)

## Set the [member weight_scale] of all tiles in the data layer with [param layer_name] that meet [param condition] to [param new_weight]
func set_weight_of_layer(layer_name: String) -> void:
	var all_point_id = astar.get_point_ids()
	for id in all_point_id:
		var tile = id_to_tile(id)
		if current_map.get_cell_tile_data(tile).get_custom_data("wall"):
			astar.set_point_weight_scale(id,10)
			continue
		astar.set_point_weight_scale(id, get_cell_custom_data(tile, layer_name))
	
#general process of converting global position to a cell position
	#1. convert global position to map node's local
	#2. convert map node's local to map coordinates
	#3. use the map coordinate to locate the closest cell in astar
	#do the other way around to convert cell position to global position

## Returns the global position of a cell position
func cell_to_global(cell_pos : Vector2i) -> Vector2:
	return current_map.to_global(current_map.map_to_local(cell_pos))

## Returns the cell position of a global position; returns [code]Vector2i(-999, 999)[/code] if no valid cell is found.
func global_to_cell(global_pos : Vector2) -> Vector2i: #returns local cell position
	var local_map_pos := current_map.local_to_map(current_map.to_local(global_pos))
	var closest_point_id = astar.get_closest_point(local_map_pos)
	var closest_cell: Vector2i = astar.get_point_position(closest_point_id)
	if local_map_pos != closest_cell: #prevents returning nonexistent cell
		return Vector2i(-999, -999)
	return closest_cell 

## Returns the cell position that is closest to a given global position; similar to [method HexNavi.global_to_cell()] but always returns a valid cell position.
func get_closest_cell_by_global_pos(global_pos : Vector2) -> Vector2i:
	var local_map_pos := current_map.local_to_map(current_map.to_local(global_pos))
	var closest_point_id = astar.get_closest_point(local_map_pos)
	var closest_cell: Vector2i = astar.get_point_position(closest_point_id)
	return closest_cell

func get_cell_custom_data(cell_pos: Vector2i, data_name: String):
	var data = current_map.get_cell_tile_data(cell_pos)
	var obj = object_map.get_cell_tile_data(cell_pos)
	var cost = 0
	
	if data:
		if data.get_custom_data("wall"):
			return
		cost = data.get_custom_data(data_name)
		if obj:
			cost += obj.get_custom_data(data_name)
	
	return cost

## Returns an array of cell positions from start to goal
func get_navi_path(start_pos : Vector2i, end_pos : Vector2i) -> PackedVector2Array:
	var start_id = tile_to_id(start_pos)
	var goal_id = tile_to_id(end_pos)
	var path_taken = astar.get_point_path(start_id, goal_id)
	return path_taken

## Use a tile position to get the id for AStar usage
func tile_to_id(pos: Vector2i) -> int: 
	#assuming that all available tiles are already mapped in astar
	if current_map.get_cell_source_id(pos) != -1:
		return astar.get_closest_point(pos)
	else: return -1

## Use an AStar point ID to get the point's tile position
func id_to_tile(id: int) -> Vector2i:
	if astar.has_point(id):
		return astar.get_point_position(id)
	return Vector2i(-1, -1)

func get_distance(pos1: Vector2i, pos2: Vector2i) -> int:
	var all_points = get_navi_path(pos1, pos2)
	return all_points.size() - 1 #excluding the first point

func get_distance_cost(pos1: Vector2i, pos2: Vector2i) -> int:
	var all_points = get_navi_path(pos1, pos2)
	var cost=0
	for tile in all_points:
		if Vector2i(tile) == pos2:
			continue
		cost+=get_cell_custom_data(tile,"weight")
	
	return cost

## Returns all neighbor cells of a given cell at [param start_pos] within [param range].
func get_all_neighbors_in_range(start_pos: Vector2i, range: int, max_weight: float = 1) -> Array[Vector2i]:
	#returns an array of cell ID
	#employs a depth first search
	var all_neighbors_id : Array[int] = []
	var starting_cell_id = tile_to_id(start_pos)
	_dfs(range, starting_cell_id, starting_cell_id, all_neighbors_id, max_weight)
	var all_neighbors_pos = all_neighbors_id.map(id_to_tile)
	var answer: Array[Vector2i]
	answer.assign(all_neighbors_pos)
	return answer
	
func _dfs(k : int, node_id : int, parent_id : int, solution_arr : Array, max_weight: float): #helper recursive function
	#godot seems to pass array by reference by default
	if k < 0 or node_id == -1:
		return
	if astar.get_point_weight_scale(node_id) > max_weight:
		return
	if !solution_arr.has(node_id):
		solution_arr.append(node_id)
	for neighbor_pos in current_map.get_surrounding_cells(astar.get_point_position(node_id)):
		var neighbor_id = tile_to_id(neighbor_pos)
		if neighbor_id != parent_id:
			_dfs(k-1, neighbor_id, node_id, solution_arr, max_weight)

## Return all tiles with [param value] in the custom data value with name [param custom_data_name]
func get_all_tile_with_layer(custom_data_name: String, value: Variant) -> Array[Vector2i]:
	var valid_tiles: Array[Vector2i] = []
	var all_point_id = astar.get_point_ids()
	for id in all_point_id:
		var tile = id_to_tile(id)
		if get_cell_custom_data(tile, custom_data_name) == value:
			valid_tiles.append(tile)
	return valid_tiles

## Returns a random tile from the registered tile set
func get_random_tile_pos() -> Vector2: #for testing and placeholder purposes
	return astar.get_point_position(randi_range(0, astar.get_point_count()-1))


func get_surrounding_cells(node:int)->Array[Vector2i]:
	return current_map.get_surrounding_cells(id_to_tile(node))

#handles tile movement cost
func get_cells_in_range_cost(start: Vector2i, mv_range: int)->Array[Vector2i]:
	var mv_arr : Array[int] = []
	var cost_arr: Dictionary
	var start_id = tile_to_id(start)
	
	dfs_cost(mv_range, start_id, start_id, mv_arr, cost_arr)
	
	var arr: Array[Vector2i]
	arr.assign(mv_arr.map(id_to_tile))
	return arr

func dfs_cost(mv:int, node:int, parent:int, mv_arr:Array, cost_arr:Dictionary):
	if !mv_arr.has(node):
		mv_arr.append(node)
	cost_arr[node] = mv
	
	for pos in get_surrounding_cells(node):
		if gameManager.is_occupied(pos):
			continue
		
		var id = tile_to_id(pos)
		if id != parent:
			var weight = get_cell_custom_data(pos,"weight")
			if weight:
				if gameManager.unit_has_skill("ignore_terrain"):
					weight=1
				var new_mv = mv-weight
				if new_mv < 0:
					continue
				
				if !cost_arr.has(id):
					dfs_cost(new_mv, id, node, mv_arr, cost_arr)
				elif new_mv > cost_arr[id]:
					cost_arr[id] = new_mv
					dfs_cost(new_mv, id, node, mv_arr, cost_arr)

func get_cells_in_attack_range(mv_range: Array[Vector2i], min:int, max:int)->Array[Vector2i]:
	if min == 0:
		return []
	
	var atk_range: Array[Vector2i]
	
	for tile in mv_range:
		for i in range(min, max+1):
			var tile_arr = get_cells_in_range(tile, i)
			for point in tile_arr:
				if point in atk_range:
					continue
				atk_range.append(point)
	
	return atk_range

func get_cells_in_range(tile:Vector2i, range:int)->Array[Vector2i]:
	var range_arr: Array[Vector2i]
	
	for i in range(1,range):
		range_arr.append(tile+Vector2i(i-range, range))
		range_arr.append(tile+Vector2i(-range, range-i))
		range_arr.append(tile+Vector2i(range, i-range))
		range_arr.append(tile+Vector2i(range-i, -range))
	
	for i in range+1:
		range_arr.append(tile+Vector2i(i, range-i))
		range_arr.append(tile+Vector2i(-i, i-range))
	
	range_arr.append(tile+Vector2i(-range,range))
	range_arr.append(tile+Vector2i(range,-range))
	
	return range_arr

func disable_point(tile:Vector2, on:bool):
	astar.set_point_disabled(tile_to_id(tile),on)
