class_name Unit extends Node2D

@onready var gameManager = $"../.."
@onready var hp_bar = $TextureProgressBar
@onready var d_zone = $DangerZone
@onready var sprite = $Sprite

var unit_resource:UnitResource
@export var unit_id:String

var stats
var hp

var mv_range
var atk_range
var team:int
var turn_end:bool

var cell: Vector2i:
	set(val):
		move(cell, val)
		position = HexNavi.cell_to_global(val)
		cell = val

func move(old:Vector2i, new:Vector2i):
	if get_parent().units.has(old):
		get_parent().units.erase(old)
		get_parent().units[new] = self
		
		if danger_enabled:
			d_zone.clear()
			danger_enabled=false

func initialize() -> void:
	cell = HexNavi.global_to_cell(position)
	stats = ClassData.data[unit_id]
	unit_resource = get_parent().unit_resources[unit_id]
	
	hp_bar.max_value = stats["hp"]
	hp_bar.value = stats["hp"]
	hp = stats["hp"]
	
	sprite.sprite_frames = unit_resource.texture
	sprite.play("default")

func take_damage(amount:int):
	if hp-amount > stats["hp"]:
		hp=stats["hp"]
	else:
		hp-=amount
	hp_bar.value = hp
	
	if hp<=0:
		get_parent().units.erase(cell)
		get_parent().unit_count-=1
		queue_free()
	
	if hp_bar.value < hp_bar.max_value:
		hp_bar.visible = true
	else:
		hp_bar.visible = false

func attack_unit(target:Unit):
	target.take_damage(calc_damage(target))

func calc_damage(target:Unit)->int:
	var damage
	if "ignore_armor" in stats["skills"]:
		damage = stats["atk"]
	else:
		damage = stats["atk"] - target.stats["def"]
	
	if damage<0:
		return 0
	return damage

func draw_overlay():
	gameManager.overlay.clear()
	
	mv_range = HexNavi.get_cells_in_range_cost(cell, stats["mv"])
	atk_range = HexNavi.get_cells_in_attack_range(mv_range, stats["min_range"], stats["max_range"])
	
	gameManager.overlay.draw_attack_range(atk_range)
	gameManager.overlay.draw_move_range(mv_range)

func draw_danger():
	gameManager.active_unit=self
	if danger_enabled:
		danger_enabled=false
		d_zone.clear()
		return
	
	mv_range = HexNavi.get_cells_in_range_cost(cell, stats["mv"])
	atk_range = HexNavi.get_cells_in_attack_range(mv_range, stats["min_range"], stats["max_range"])
	d_zone.draw_attack_range(atk_range.map(atk_map_function))
	
	danger_enabled=true
	gameManager.active_unit=null
func atk_map_function(tile:Vector2i):
	return tile-cell

func _to_string() -> String:
	return name

func end_turn():
	turn_end = true
	if get_parent().all_units_end():
		gameManager.next_turn()

#enemy ai
var danger_enabled:bool

func auto_move():
	var targets = get_parent().get_target_units()
	mv_range = HexNavi.get_cells_in_range_cost(cell, stats["mv"])
	atk_range = HexNavi.get_cells_in_attack_range(mv_range, stats["min_range"], stats["max_range"])
	
	var targets_in_range=[]
	for child in targets:
		if child in atk_range:
			targets_in_range.append(targets[child])
	
	if targets_in_range.is_empty():
		#find closest unit
		var target
		var close_cost=1000
		for unit in targets:
			var cost = HexNavi.get_distance_cost(cell,unit)
			if cost<close_cost:
				target=unit
				close_cost=HexNavi.get_distance_cost(cell,unit)
		#find the closest available tile to target
		cell = valid_move_point(target)
	
	else:
		targets_in_range.sort_custom(sort_target_priority)
		for target in targets_in_range:
			var available = HexNavi.get_cells_in_attack_range([target.cell], stats["min_range"], stats["max_range"])
			if cell in available:
				attack_unit(target)
				return
			for tile in available:
				if !get_parent().units.has(tile) and tile in mv_range:
					cell=tile
					attack_unit(target)
					return
		cell = valid_move_point(targets_in_range[0].cell)
		
func valid_move_point(target:Vector2i)->Vector2i:
	var pos = cell
	var cost = HexNavi.get_distance_cost(cell,target)
	
	for tile in mv_range:
		if get_parent().units.has(tile):
			continue
		var new_cost = HexNavi.get_distance_cost(tile,target)
		if new_cost<cost:
			cost=new_cost
			pos=tile
	
	return pos

func sort_target_priority(unit1:Unit, unit2:Unit):
	if unit1.hp-calc_damage(unit1)==0:
		return true
	if calc_damage(unit1) > calc_damage(unit2):
		return true
	return false
